# Aula 06 — Biblioteca de Módulos Terraform (TechNova)

## Visão Geral

Esta pasta contém uma **biblioteca de módulos Terraform reutilizáveis** — VPC, Security Group, EC2 e RDS — usada para provisionar ambientes completos da TechNova. Os mesmos módulos são chamados duas vezes, com variáveis diferentes, para criar os ambientes `dev` e `staging`, eliminando a duplicação de código entre eles (princípio DRY).

## Arquitetura

Dependências entre módulos dentro de cada ambiente:

```
                         module.vpc
                (VPC + subnets públicas/privadas
                    via for_each + IGW + RT)
                    │                    │
          vpc_id ───┤                    ├─── private_subnet_ids
                     ▼                    ▼
            module.api_sg          module.rds_sg
         (SG: HTTP 80, SSH 22)   (SG: PostgreSQL 5432
                                   apenas da própria VPC)
                     │                    │
           sg_id ────┤                    ├──── sg_id
                     ▼                    ▼
            module.api_server        module.database
              (EC2 t2.micro)      (RDS PostgreSQL db.t3.micro
                                     + DB Subnet Group)
```

`environments/dev` e `environments/staging` são dois **root modules** independentes que chamam a mesma biblioteca em `modules/` com CIDRs, nomes e `.tfvars` próprios.

## Módulos Disponíveis

| Módulo | Descrição | Principais Inputs | Principais Outputs |
|---|---|---|---|
| [`vpc`](modules/vpc) | VPC completa com subnets dinâmicas (`for_each`), Internet Gateway e Route Table pública | `vpc_cidr`, `project_name`, `environment`, `subnets` | `vpc_id`, `public_subnet_ids`, `private_subnet_ids` |
| [`security-group`](modules/security-group) | Security Group genérico — aceita regras de ingress como lista de objetos | `name`, `vpc_id`, `ingress_rules`, `environment`, `project_name` | `sg_id` |
| [`ec2`](modules/ec2) | Instância EC2 reutilizável com AMI, subnet e SGs configuráveis | `instance_name`, `ami_id`, `subnet_id`, `security_group_ids`, `key_name` | `instance_id`, `public_ip`, `private_ip` |
| [`rds`](modules/rds) | Instância RDS PostgreSQL + DB Subnet Group | `db_name`, `db_username`, `db_password`, `subnet_ids`, `security_group_ids` | `db_endpoint`, `db_name`, `db_port` |

### Módulo VPC

**Descrição:** Cria VPC, subnets dinâmicas (`for_each`), Internet Gateway e Route Table pública associada apenas às subnets do tipo `public`.

**Inputs:**
| Nome | Tipo | Obrigatório | Descrição |
|------|------|-------------|-----------|
| `vpc_cidr` | string | Sim | CIDR block da VPC |
| `project_name` | string | Sim | Nome do projeto (tags/nomes) |
| `environment` | string | Sim | Ambiente (dev, staging, ...) |
| `subnets` | map(object) | Sim | Mapa `nome => { cidr, az, type }` |

**Outputs:**
| Nome | Descrição |
|------|-----------|
| `vpc_id` | ID da VPC criada |
| `vpc_cidr` | CIDR da VPC |
| `subnet_ids` | Mapa nome → ID de todas as subnets |
| `public_subnet_ids` | Lista de IDs das subnets públicas |
| `private_subnet_ids` | Lista de IDs das subnets privadas |

**Exemplo de uso:**
```hcl
module "vpc" {
  source       = "../../modules/vpc"
  vpc_cidr     = "10.0.0.0/16"
  project_name = "technova"
  environment  = "dev"
  subnets = {
    "public-1"  = { cidr = "10.0.1.0/24", az = "us-east-1a", type = "public" }
    "private-1" = { cidr = "10.0.3.0/24", az = "us-east-1a", type = "private" }
  }
}
```

### Módulo Security Group

**Descrição:** SG genérico reutilizado tanto para a API (HTTP/SSH) quanto para o RDS (PostgreSQL restrito à VPC). Regras de ingress TCP recebidas como lista de objetos `{ port, cidr, description }`; egress libera todo o tráfego de saída por padrão.

**Inputs:**
| Nome | Tipo | Obrigatório | Descrição |
|------|------|-------------|-----------|
| `name` | string | Sim | Nome do Security Group |
| `vpc_id` | string | Sim | ID da VPC |
| `ingress_rules` | list(object) | Não (default `[]`) | Lista de `{ port, cidr, description }` |
| `environment` | string | Sim | Ambiente |
| `project_name` | string | Sim | Nome do projeto |

**Outputs:**
| Nome | Descrição |
|------|-----------|
| `sg_id` | ID do Security Group criado |

**Exemplo de uso:**
```hcl
module "api_sg" {
  source       = "../../modules/security-group"
  name         = "technova-dev-api-sg"
  vpc_id       = module.vpc.vpc_id
  environment  = "dev"
  project_name = "technova"
  ingress_rules = [
    { port = 80, cidr = "0.0.0.0/0", description = "HTTP" },
    { port = 22, cidr = "0.0.0.0/0", description = "SSH" },
  ]
}
```

### Módulo EC2

**Descrição:** Instância EC2 reutilizável (padrão `t2.micro`), com AMI, subnet, Security Groups e `user_data` configuráveis.

**Inputs:**
| Nome | Tipo | Obrigatório | Descrição |
|------|------|-------------|-----------|
| `instance_name` | string | Sim | Nome da instância (tag `Name`) |
| `instance_type` | string | Não (default `t2.micro`) | Tipo da instância |
| `ami_id` | string | Sim | AMI ID |
| `subnet_id` | string | Sim | Subnet onde a instância é criada |
| `security_group_ids` | list(string) | Sim | Lista de SG IDs |
| `key_name` | string | Não (default `""`) | Key pair SSH |
| `user_data` | string | Não (default `""`) | Script de inicialização |
| `environment` / `project_name` | string | Sim | Tags |

**Outputs:**
| Nome | Descrição |
|------|-----------|
| `instance_id` | ID da instância |
| `public_ip` | IP público |
| `private_ip` | IP privado |

**Exemplo de uso:**
```hcl
module "api_server" {
  source              = "../../modules/ec2"
  instance_name       = "technova-dev-api"
  ami_id              = data.aws_ami.amazon_linux.id
  subnet_id           = module.vpc.public_subnet_ids[0]
  security_group_ids  = [module.api_sg.sg_id]
  key_name            = "technova-key"
  environment         = "dev"
  project_name        = "technova"
}
```

### Módulo RDS

**Descrição:** DB Subnet Group (nas subnets privadas) + instância RDS PostgreSQL (`db.t3.micro`), com configurações voltadas a desenvolvimento (`skip_final_snapshot = true`, sem backups nem multi-AZ).

**Inputs:**
| Nome | Tipo | Obrigatório | Descrição |
|------|------|-------------|-----------|
| `db_name` | string | Sim | Nome do database |
| `db_username` | string | Sim | Usuário master |
| `db_password` | string (sensitive) | Sim | Senha master |
| `subnet_ids` | list(string) | Sim | Subnets privadas para o DB Subnet Group |
| `security_group_ids` | list(string) | Sim | SG IDs do RDS |
| `instance_class` | string | Não (default `db.t3.micro`) | Classe da instância |
| `environment` / `project_name` | string | Sim | Tags/nomes |

**Outputs:**
| Nome | Descrição |
|------|-----------|
| `db_endpoint` | Endpoint de conexão |
| `db_name` | Nome do database |
| `db_port` | Porta do banco |

**Exemplo de uso:**
```hcl
module "database" {
  source              = "../../modules/rds"
  db_name             = "technova_dev"
  db_username         = "technova_admin"
  db_password         = var.db_password
  subnet_ids          = module.vpc.private_subnet_ids
  security_group_ids  = [module.rds_sg.sg_id]
  environment         = "dev"
  project_name        = "technova"
}
```

## Como Usar — Criando um Novo Ambiente

Para criar um ambiente novo (ex: `prod`), basta copiar `environments/dev/` para `environments/prod/`, ajustar os `default` em `variables.tf` (CIDR, nomes) e o `terraform.tfvars` — os módulos em `modules/` não mudam.

```bash
cd aula-06/environments/dev
cp terraform.tfvars.example terraform.tfvars
# edite terraform.tfvars com a senha do banco

terraform init
terraform validate
terraform plan
```

## Pré-requisitos

- **Terraform** ≥ 1.0
- **AWS CLI** configurado com as credenciais do **AWS Academy Learner Lab** (`source aws-creds.sh`, região `us-east-1`)
- Um **Key Pair** EC2 existente (ou ajuste `key_name` para `""` para pular a associação de chave)

## Ambientes

| Aspecto | Dev | Staging |
|---|---|---|
| VPC CIDR | `10.0.0.0/16` | `10.1.0.0/16` |
| Subnets Públicas | `10.0.1.0/24`, `10.0.2.0/24` | `10.1.1.0/24`, `10.1.2.0/24` |
| Subnets Privadas | `10.0.3.0/24`, `10.0.4.0/24` | `10.1.3.0/24`, `10.1.4.0/24` |
| DB Name | `technova_dev` | `technova_staging` |
| Naming Pattern | `technova-dev-*` | `technova-staging-*` |

> **Atenção Learner Lab:** rodar os dois ambientes simultaneamente dobra o consumo de recursos. Valide com `terraform plan` (sem `apply`) ou teste um ambiente por vez, e sempre execute `terraform destroy` após os testes.
