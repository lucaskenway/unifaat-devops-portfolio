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
  description = "Bloco CIDR da VPC (diferente da Aula 10 para as duas poderem coexistir)"
  type        = string
  default     = "10.11.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "Subnets públicas, uma por AZ (o ALB exige pelo menos duas AZs)"
  type        = list(string)
  default     = ["10.11.1.0/24", "10.11.2.0/24"]
}

variable "availability_zones" {
  description = "AZs das subnets públicas, na mesma ordem de public_subnet_cidrs"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "instance_type" {
  description = "Tipo das instâncias EC2 Blue e Green"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "Key Pair das EC2 (o mesmo da Aula 10, criado por aula-10/scripts/bootstrap-backend.sh)"
  type        = string
  default     = "technova-aula10-deploy"
}

variable "app_port" {
  description = "Porta em que a TechNova API escuta nas instâncias"
  type        = number
  default     = 3000
}

variable "health_check_path" {
  description = "Path do health check dos Target Groups (readiness, não só liveness)"
  type        = string
  default     = "/health/ready"
}

variable "ssh_cidr_blocks" {
  # ai-review-ignore: runners do GitHub Actions não têm IP fixo; SSH só aceita a chave do deploy
  description = "Origens liberadas para SSH (deploy do workflow; acesso só com a chave privada)"
  type        = list(string)
  default     = ["0.0.0.0/0"] # ai-review-ignore: ver EXPLICACAO.md §6 (SSM seria o ideal)
}

variable "ecr_repository" {
  description = "Nome do repositório ECR da imagem (criado na Aula 09)"
  type        = string
  default     = "technova-api"
}
