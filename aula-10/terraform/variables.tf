variable "aws_region" {
  description = "Região AWS (o Learner Lab só permite us-east-1)"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Nome do projeto usado nas tags"
  type        = string
  default     = "TechNova"
}

variable "environment" {
  description = "Ambiente ao qual esta configuração pertence"
  type        = string
  default     = "production"
}

variable "aluno" {
  description = "Nome completo do aluno responsável pela entrega"
  type        = string
  default     = "Weslley Lucas Souza Alves"
}

variable "ra" {
  description = "RA do aluno, usado como prefixo dos recursos para evitar conflitos"
  type        = string
  default     = "6325226"
}

variable "vpc_cidr" {
  description = "Bloco CIDR da VPC"
  type        = string
  default     = "10.10.0.0/16"
}

variable "public_subnet_cidr" {
  description = "Bloco CIDR da subnet pública onde fica a EC2"
  type        = string
  default     = "10.10.1.0/24"
}

variable "availability_zone" {
  description = "AZ da subnet pública"
  type        = string
  default     = "us-east-1a"
}

variable "instance_type" {
  description = "Tipo da instância EC2"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "Key Pair da EC2, criado por scripts/bootstrap-backend.sh (a chave privada vira o secret EC2_SSH_KEY)"
  type        = string
  default     = "technova-aula10-deploy"
}

variable "app_port" {
  description = "Porta em que a TechNova API escuta"
  type        = number
  default     = 3000
}

variable "ssh_cidr_blocks" {
  # ai-review-ignore: runners do GitHub Actions não têm IP fixo; SSH só aceita a chave do deploy
  description = "Origens liberadas para SSH (runners do GitHub Actions sem IP fixo; acesso só com a chave privada)"
  type        = list(string)
  default     = ["0.0.0.0/0"] # ai-review-ignore: ver gitops-cd-analise.md §6 (SSM seria o ideal)
}

variable "ecr_repository" {
  description = "Nome do repositório ECR da imagem (criado na Aula 09)"
  type        = string
  default     = "technova-api"
}
