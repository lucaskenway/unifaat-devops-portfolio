# variables.tf — environments/dev

variable "aws_region" {
  description = "Região AWS"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Nome do projeto (usado em tags e nomes)"
  type        = string
  default     = "technova"
}

variable "environment" {
  description = "Ambiente"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "CIDR block da VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnets" {
  description = "Mapa de subnets do ambiente dev"
  type = map(object({
    cidr = string
    az   = string
    type = string
  }))
  default = {
    "public-1"  = { cidr = "10.0.1.0/24", az = "us-east-1a", type = "public" }
    "public-2"  = { cidr = "10.0.2.0/24", az = "us-east-1b", type = "public" }
    "private-1" = { cidr = "10.0.3.0/24", az = "us-east-1a", type = "private" }
    "private-2" = { cidr = "10.0.4.0/24", az = "us-east-1b", type = "private" }
  }
}

variable "key_name" {
  description = "Nome do key pair SSH para a instância EC2"
  type        = string
  default     = "technova-key"
}

variable "db_name" {
  description = "Nome do database"
  type        = string
  default     = "technova_dev"
}

variable "db_username" {
  description = "Usuário master do banco"
  type        = string
  default     = "technova_admin"
}

variable "db_password" {
  description = "Senha master do banco (use apenas caracteres alfanuméricos)"
  type        = string
  sensitive   = true
}

variable "db_instance_class" {
  description = "Classe da instância RDS"
  type        = string
  default     = "db.t3.micro"
}
