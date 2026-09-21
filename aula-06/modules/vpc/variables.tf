# variables.tf — modules/vpc

variable "vpc_cidr" {
  description = "CIDR block da VPC"
  type        = string
}

variable "project_name" {
  description = "Nome do projeto (usado em tags e nomes)"
  type        = string
}

variable "environment" {
  description = "Ambiente (dev, staging, prod)"
  type        = string
}

variable "subnets" {
  description = "Mapa de subnets a criar. Chave = nome da subnet, valor = { cidr, az, type }"
  type = map(object({
    cidr = string
    az   = string
    type = string
  }))
}
