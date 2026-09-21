# variables.tf — modules/rds

variable "db_name" {
  description = "Nome do database"
  type        = string
}

variable "db_username" {
  description = "Usuário master do banco"
  type        = string
}

variable "db_password" {
  description = "Senha master do banco (use apenas caracteres alfanuméricos)"
  type        = string
  sensitive   = true
}

variable "subnet_ids" {
  description = "Subnet IDs (privadas) para o DB Subnet Group"
  type        = list(string)
}

variable "security_group_ids" {
  description = "Security Group IDs a associar à instância RDS"
  type        = list(string)
}

variable "instance_class" {
  description = "Classe da instância RDS"
  type        = string
  default     = "db.t3.micro"
}

variable "environment" {
  description = "Ambiente (dev, staging, prod)"
  type        = string
}

variable "project_name" {
  description = "Nome do projeto (usado em tags e nomes)"
  type        = string
}
