variable "aws_region" {
  description = "Região AWS onde os recursos IAM serão criados"
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
  default     = "training"
}

variable "aluno" {
  description = "Nome completo do aluno responsável pela entrega"
  type        = string
  default     = "Weslley Lucas"
}

variable "ra" {
  description = "RA (matrícula) do aluno, usado como prefixo dos recursos para evitar conflitos na conta compartilhada"
  type        = string
  default     = "6325226"
}
