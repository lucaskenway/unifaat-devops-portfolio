variable "aws_region" {
  description = "Região AWS onde os recursos serão criados"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Nome do projeto/empresa fictícia usado nas tags e nos nomes de recursos"
  type        = string
  default     = "TechNova"
}

variable "environment" {
  description = "Ambiente ao qual esta configuração pertence"
  type        = string
  default     = "development"
}

variable "aluno" {
  description = "Nome completo do aluno responsável pela entrega"
  type        = string
  default     = "Weslley Lucas Souza Alves"
}

variable "ra" {
  description = "RA (matrícula) do aluno, usado como prefixo dos recursos para evitar conflitos na conta compartilhada"
  type        = string
  default     = "6325226"
}

variable "vpc_cidr" {
  description = "Bloco CIDR da VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Availability Zones usadas para distribuir as subnets (Multi-AZ)"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "public_subnet_cidrs" {
  description = "Blocos CIDR das subnets públicas, uma por AZ"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.3.0/24"]
}

variable "private_subnet_cidrs" {
  description = "Blocos CIDR das subnets privadas, uma por AZ"
  type        = list(string)
  default     = ["10.0.2.0/24", "10.0.4.0/24"]
}

variable "instance_type" {
  description = "Tipo da instância EC2 (mantido em Free Tier)"
  type        = string
  default     = "t2.micro"
}

variable "public_key_path" {
  description = "Caminho local da chave pública SSH registrada na AWS"
  type        = string
  default     = "~/.ssh/technova-key.pub"
}

variable "key_name" {
  description = "Nome do Key Pair criado na AWS"
  type        = string
  default     = "technova-key"
}
