terraform {
  required_version = ">= 1.7"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Backend remoto S3 + DynamoDB (padrão da Aula 05). Com o state remoto, o plan do PR e
  # o apply do merge enxergam a mesma infraestrutura e o lock impede applies simultâneos.
  #
  # Configuração parcial: o bucket é "technova-tfstate-<ACCOUNT_ID>" e entra no init via
  # -backend-config, porque a conta do Learner Lab pode mudar entre sessões.
  # O bucket e a tabela são criados uma única vez por ../scripts/bootstrap-backend.sh.
  backend "s3" {
    key            = "aula-10/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "technova-terraform-locks"
  }
}

# As credenciais vêm do ambiente: no GitHub Actions, das 3 credenciais de sessão do
# Learner Lab (secrets); localmente, do ~/.aws/credentials copiado de "AWS Details".
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.common_tags
  }
}
