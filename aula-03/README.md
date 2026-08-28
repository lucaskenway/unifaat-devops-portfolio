# Aula 03 — Terraform + IAM | RA 6325226

## Design da Estrutura IAM

A estrutura separa responsabilidades em dois grupos porque desenvolvedores e
engenheiros de plataforma têm necessidades de acesso muito diferentes:
desenvolvedores só precisam **ler** dados em S3 para trabalhar no dia a dia,
enquanto a equipe de Platform Engineering precisa **operar** instâncias EC2
(start/stop) além de ler e gravar em S3. Misturar as duas coisas num único
grupo obrigaria a dar permissão de EC2 para quem nunca vai usar, violando o
menor privilégio.

- `6325226-technova-developers` — Juliana, Rafael e Lucas (o estagiário). Todos
  precisam de leitura em S3, então a policy de leitura fica no grupo, não no
  usuário — assim, incluir/remover alguém do time é só uma mudança de
  membership, sem reescrever policies.
- `6325226-technova-platform-eng` — apenas Rafael, que acumula a função. Ele
  fica nos dois grupos e herda a soma das permissões (S3 read do
  `developers` + EC2/S3 do `platform-eng`).

O estagiário (Lucas) não tem um terceiro grupo dedicado: ele está apenas em
`developers`, e a policy de **deny explícito** para ações destrutivas também
foi anexada a esse grupo. Isso já restringe qualquer membro júnior sem
precisar duplicar a policy de leitura em um grupo `interns` separado — menos
peças móveis, mesmo resultado de segurança.

## Princípio do Menor Privilégio

O princípio diz que cada identidade deve ter **apenas** as permissões
necessárias para a sua função, nem mais, nem menos — e nada "por garantia".

Dois exemplos de como isso foi aplicado no código:

1. Em `policies.tf`, a policy `ec2-s3-full` não dá `ec2:StartInstances` /
   `ec2:StopInstances` sobre qualquer instância: a `condition` exige que o
   recurso tenha a tag `Project = TechNova`. Mesmo alguém do time de
   plataforma não consegue ligar/desligar instâncias de outros projetos na
   mesma conta.
2. A policy `s3-read` limita `resources` a `arn:aws:s3:::technova-*` — não é
   `"*"`. Um developer não consegue nem listar buckets de outros projetos,
   só os que pertencem à TechNova.

Se eu tivesse usado a managed policy `AmazonS3FullAccess` no lugar da custom
policy, qualquer usuário do grupo `developers` teria `s3:*` sobre **todos os
buckets da conta** — incluindo delete, mudança de bucket policy e acesso a
dados de outros projetos que nada têm a ver com a TechNova. Um erro de
digitação num script rodando com essas credenciais poderia apagar dados de
produção de outro time inteiro. A policy custom reduz esse raio de explosão
a "ler objetos dentro de buckets que começam com `technova-`".

## Diagrama de Permissões

```
                         ┌────────────────────────────┐
                         │  Group: developers          │
User: juliana-dev ─────► │  - s3-read                  │ ───► technova-* (S3, read-only)
User: lucas-intern ────► │  - deny-destructive (Deny)  │
                         └────────────────────────────┘
                                      ▲
                                      │ (também membro de)
User: rafael-platform ───────────────┤
                                      │
                         ┌────────────────────────────┐
                         │  Group: platform-eng         │
                         │  - ec2-s3-full               │ ───► EC2 start/stop (tag Project=TechNova)
                         └────────────────────────────┘            + technova-* (S3, read/write)

Role: technova-ec2-role
  Trust Policy: Principal = ec2.amazonaws.com (sts:AssumeRole)
  Permissions:  s3:GetObject/PutObject/ListBucket em technova-app-data-*
        │
        ▼
Instance Profile: technova-ec2-profile
        │
        ▼
   EC2 instance ──► assume role ──► credenciais temporárias ──► S3 (technova-app-data-*)
```

## Comandos Utilizados

```bash
terraform init
terraform validate
terraform plan
terraform apply
terraform destroy
```

## Reflexão

Criar IAM manualmente pelo Console AWS funciona, mas cada clique fica só na
memória de quem fez — não há histórico de "por que essa policy tem essa
permissão" nem forma fácil de saber se duas pessoas criaram a mesma coisa de
jeitos diferentes. Com Terraform, a estrutura inteira (groups, users,
policies, roles) vive em arquivos versionados: dá para revisar em Pull
Request antes de aplicar, comparar com `terraform plan` o que vai mudar antes
de mudar de fato, e recriar o ambiente inteiro do zero de forma idêntica caso
precise. Para uma equipe, isso é mais seguro e mais auditável porque toda
mudança de permissão passa por revisão de código, fica registrada no
histórico do Git com autor e data, e pode ser revertida com um `git revert`
— coisas que o Console não oferece.
