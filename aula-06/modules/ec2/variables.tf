# variables.tf — modules/ec2

variable "instance_name" {
  description = "Nome da instância EC2 (usado na tag Name)"
  type        = string
}

variable "instance_type" {
  description = "Tipo da instância"
  type        = string
  default     = "t2.micro"
}

variable "ami_id" {
  description = "AMI ID para a instância"
  type        = string
}

variable "subnet_id" {
  description = "ID da subnet onde a instância será criada"
  type        = string
}

variable "security_group_ids" {
  description = "Lista de Security Group IDs a associar à instância"
  type        = list(string)
}

variable "key_name" {
  description = "Nome do key pair SSH"
  type        = string
  default     = ""
}

variable "user_data" {
  description = "User data script (opcional)"
  type        = string
  default     = ""
}

variable "environment" {
  description = "Ambiente (dev, staging, prod)"
  type        = string
}

variable "project_name" {
  description = "Nome do projeto (usado em tags)"
  type        = string
}
