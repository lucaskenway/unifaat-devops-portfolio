terraform {
  required_version = ">= 1.7"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Mesmo backend da Aula 10 (bucket technova-tfstate-<ACCOUNT_ID> + lock no DynamoDB,
  # criados por aula-10/scripts/bootstrap-backend.sh), com uma key própria da Aula 11.
  # Configuração parcial: o bucket entra no init via -backend-config.
  backend "s3" {
    key            = "aula-11/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "technova-terraform-locks"
  }
}

# Credenciais do ambiente: ~/.aws/credentials copiado de "AWS Details" no Learner Lab
# (inclui aws_session_token)
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.common_tags
  }
}
