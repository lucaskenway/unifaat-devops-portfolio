terraform {
  required_version = ">= 1.7"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4"
    }
  }

  # Mesmo backend das Aulas 10/11 (bucket technova-tfstate-<ACCOUNT_ID> + lock no
  # DynamoDB), key própria. O bucket entra no init: -backend-config=bucket=...
  backend "s3" {
    key            = "aula-12/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "technova-terraform-locks"
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.common_tags
  }
}
