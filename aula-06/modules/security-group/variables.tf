# variables.tf — modules/security-group

variable "name" {
  description = "Nome do Security Group"
  type        = string
}

variable "vpc_id" {
  description = "ID da VPC onde o Security Group será criado"
  type        = string
}

variable "ingress_rules" {
  description = "Lista de regras de ingress (porta única TCP, CIDR de origem e descrição)"
  type = list(object({
    port        = number
    cidr        = string
    description = string
  }))
  default = []
}

variable "environment" {
  description = "Ambiente (dev, staging, prod)"
  type        = string
}

variable "project_name" {
  description = "Nome do projeto (usado em tags)"
  type        = string
}
