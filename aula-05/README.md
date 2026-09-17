# Infraestrutura TechNova — Aula 05: RDS e Remote State

Dois laboratórios em Terraform: uma VPC com RDS PostgreSQL e EC2 (`aula-05-rds/`), e um backend remoto de state em S3 + DynamoDB (`aula-05-backend/`).

## Estrutura

- `aula-05-rds/` — VPC (2 AZs, subnets públicas/privadas), RDS PostgreSQL em subnet privada, EC2 na subnet pública conectando ao banco via `psql`.
- `aula-05-backend/` — bucket S3 (versionado, criptografado, acesso público bloqueado) e tabela DynamoDB para state remoto com locking.
- `main.tf` / `providers.tf` / `variables.tf` / `outputs.tf` / `.gitignore` (raiz de `aula-05/`) — cópia consolidada do Lab 1 (`aula-05-rds/`), mantida no nível raiz para casar com o layout de entrega esperado pela disciplina. A fonte organizada por responsabilidade (`vpc.tf`, `rds.tf`, `ec2.tf`) continua em `aula-05-rds/`.

## Como usar

### Pré-requisitos

- AWS CLI configurado com credenciais válidas do AWS Academy Learner Lab
- Terraform >= 1.0

### Lab 1 — VPC + RDS + EC2

```bash
cd aula-05-rds
cp terraform.tfvars.example terraform.tfvars   # preencha com uma senha de banco
terraform init
terraform plan
terraform apply
```

Testar a conexão:

```bash
psql -h $(terraform output -raw rds_address) -U technova_admin -d technova -p 5432 -c "SELECT version();"
psql -h $(terraform output -raw rds_address) -U technova_admin -d technova -p 5432 -f seed.sql
```

### Lab 2 — Backend remoto (S3 + DynamoDB)

```bash
cd aula-05-backend
terraform init
terraform apply
```

### Como destruir

```bash
terraform destroy
```

> Execute sempre `terraform destroy` ao final para evitar custos na conta AWS.

## Problema real encontrado: SCP bloqueia `aws_s3_bucket` no Terraform

Ao rodar `terraform apply` em `aula-05-backend/` na conta do AWS Academy Learner Lab, o DynamoDB e a chave KMS foram criados normalmente, mas a criação do bucket S3 falhou:

```
Error: reading S3 Bucket (...) object lock configuration: operation error S3:
GetObjectLockConfiguration, ... AccessDenied: ... is not authorized to perform:
s3:GetBucketObjectLockConfiguration ... with an explicit deny in a service
control policy: arn:aws:organizations::445917269142:policy/o-.../p-...
```

**Causa:** o AWS Provider sempre chama `GetBucketObjectLockConfiguration` ao criar/ler um `aws_s3_bucket` (para popular o atributo computado `object_lock_configuration`). A conta do Learner Lab tem uma Service Control Policy organizacional que nega essa chamada para qualquer usuário — não contornável no nível do código Terraform ou da IAM role do aluno.

**Solução aplicada:** o bucket foi criado fora do `apply` que falhou; versionamento, encriptação (com a mesma KMS key gerada pelo Terraform) e bloqueio de acesso público foram aplicados diretamente via `aws s3api`, fora do Terraform. O `s3.tf` permanece correto e funciona normalmente em uma conta AWS sem essa SCP — apenas o `aws_s3_bucket.state` não pôde ser lido/gerenciado pelo Terraform nesta conta específica.

O backend remoto foi migrado com sucesso depois disso (`terraform init -migrate-state` em `aula-05-rds/`), com state no S3 e locking via DynamoDB funcionais.

## Resumo de evidências

| Requisito | Status |
|---|---|
| VPC + subnets em 2 AZs | ✅ criado |
| RDS PostgreSQL (db.t3.micro) | ✅ criado, `SELECT version()` funcionando |
| EC2 conectando ao RDS | ✅ psql via VPC funcionando |
| Dados persistentes (tabela `orders`) | ✅ 3 registros inseridos e consultados |
| Remote State (S3 + DynamoDB) | ✅ funcional (bucket provisionado via AWS CLI por causa da SCP do lab) |
| `terraform plan` limpo | ✅ "No changes" |
| `terraform destroy` após evidências | ✅ VPC/RDS/EC2 e KMS/DynamoDB destruídos |
