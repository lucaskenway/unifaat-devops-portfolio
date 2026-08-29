# Infraestrutura TechNova — Aula 04

Infraestrutura de rede Multi-AZ (VPC + EC2) para a TechNova, provisionada com Terraform, pronta para receber um Load Balancer no futuro.

## Diagrama da Arquitetura

```
                              Internet
                                 │
                        ┌────────▼────────┐
                        │ Internet Gateway │
                        └────────┬────────┘
                                 │
                     ┌───────────▼───────────┐
                     │   Route Table pública   │
                     │  0.0.0.0/0 → IGW        │
                     └─────┬───────────┬───────┘
                           │           │
        VPC 10.0.0.0/16    │           │
   ┌───────────────────────┼───────────┼───────────────────────┐
   │        AZ us-east-1a  │           │  AZ us-east-1b         │
   │  ┌─────────────────┐  │  ┌─────────────────┐               │
   │  │ Subnet pública   │◄─┘  │ Subnet pública   │               │
   │  │ 10.0.1.0/24      │     │ 10.0.3.0/24      │               │
   │  │                  │     │                  │               │
   │  │  ┌────────────┐  │     │   (reservada     │               │
   │  │  │ EC2 t2.micro│  │     │   p/ 2ª AZ do   │               │
   │  │  │ API :3000  │  │     │   futuro ALB)    │               │
   │  │  └────────────┘  │     │                  │               │
   │  └─────────────────┘     └─────────────────┘               │
   │                                                             │
   │  ┌─────────────────┐     ┌─────────────────┐               │
   │  │ Subnet privada   │     │ Subnet privada   │               │
   │  │ 10.0.2.0/24      │     │ 10.0.4.0/24      │               │
   │  │ (RT padrão, sem  │     │ (RT padrão, sem  │               │
   │  │  rota p/ IGW)    │     │  rota p/ IGW)    │               │
   │  │  reservada p/ RDS│     │  reservada p/ RDS│               │
   │  └─────────────────┘     └─────────────────┘               │
   └─────────────────────────────────────────────────────────────┘

   Security Groups:
   - api-sg: 22 (SSH) e 3000 (API) de 0.0.0.0/0
   - db-sg : 5432 (PostgreSQL) apenas de 10.0.0.0/16
```

## Como usar

### Pré-requisitos

- AWS CLI configurado com credenciais válidas do AWS Academy Learner Lab (`aws sts get-caller-identity`)
- Terraform >= 1.0
- Chave SSH gerada localmente:
  ```bash
  ssh-keygen -t rsa -b 4096 -f ~/.ssh/technova-key -N ""
  ```

### Comandos

```bash
cd aula-04
terraform init
terraform plan
terraform apply
```

### Como testar

```bash
export API_IP=$(terraform output -raw ec2_public_ip)

curl http://$API_IP:3000
curl http://$API_IP:3000/health
curl http://$API_IP:3000/orders

ssh -i ~/.ssh/technova-key ec2-user@$API_IP "node --version && aws sts get-caller-identity"
```

### Como destruir

```bash
terraform destroy
```

> Execute sempre `terraform destroy` ao final para evitar custos na conta AWS.

## Decisões técnicas

- **Multi-AZ**: as subnets públicas e privadas foram distribuídas em duas Availability Zones (`us-east-1a` e `us-east-1b`) via `count` sobre listas de CIDRs/AZs, preparando o terreno para um Application Load Balancer (que exige subnets em pelo menos 2 AZs) e maior resiliência a falha de uma zona.
- **Separação público/privado**: a subnet pública tem rota `0.0.0.0/0 → IGW` e recebe IP público automático — é onde fica a EC2 da API (e, futuramente, o ALB). As subnets privadas ficam sem rota para a internet (usam a Route Table padrão da VPC), reservadas para o banco de dados (RDS) da Aula 05.
- **Instance Profile em vez de access keys**: a EC2 usa Instance Profile (nenhuma credencial fixa no código ou na instância). Na conta pessoal, isso seria um `aws_iam_role` (trust `ec2.amazonaws.com`) com `AmazonS3ReadOnlyAccess` anexado — exatamente como modelado inicialmente em `iam.tf`. **Limitação do AWS Academy Learner Lab:** o role assumido pelo aluno (`voclabs`) não tem permissão `iam:CreateRole`/`iam:AttachRolePolicy` (só a Academy pode gerenciar IAM nessa conta). Por isso o `iam.tf` foi ajustado para referenciar via `data` o `LabInstanceProfile` pré-existente na conta (que usa o `LabRole`, já com permissões amplas, incluindo leitura de S3), em vez de criar um role novo.
- **AMI via data source**: a AMI do Amazon Linux 2023 é resolvida dinamicamente (`data "aws_ami"`), nunca fixada por ID, garantindo que o Terraform sempre use a versão mais recente.
- **Prefixo por RA**: todos os nomes de recursos são prefixados com `${var.ra}-technova` para evitar colisões na conta compartilhada do Learner Lab.
- **Descrições em ASCII**: os campos `description` dos Security Groups foram escritos em inglês porque a API EC2 rejeita caracteres não-ASCII (como acentos) em `GroupDescription`.

## Recursos criados

| Recurso | Função |
|---|---|
| `aws_vpc.main` | VPC principal (10.0.0.0/16) |
| `aws_subnet.public[2]` | 2 subnets públicas (uma por AZ) |
| `aws_subnet.private[2]` | 2 subnets privadas (uma por AZ) |
| `aws_internet_gateway.main` | Gateway de acesso à internet |
| `aws_route_table.public` + `aws_route_table_association.public[2]` | Roteamento das subnets públicas para o IGW |
| `aws_security_group.api` | Firewall da API (22, 3000) |
| `aws_security_group.db` | Firewall do banco de dados (5432, somente VPC) |
| `data.aws_iam_instance_profile.lab` | Instance Profile `LabInstanceProfile` (LabRole) pré-existente da Academy, vinculado à instância |
| `aws_key_pair.main` | Chave SSH registrada na AWS |
| `data.aws_ami.al2023` | AMI mais recente do Amazon Linux 2023 |
| `aws_instance.api` | EC2 t2.micro com a API TechNova via User Data |
