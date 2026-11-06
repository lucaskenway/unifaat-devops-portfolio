variable "aws_region" {
  description = "Região AWS (o Learner Lab só permite us-east-1)"
  type        = string
  default     = "us-east-1"
}

variable "aluno" {
  description = "Nome completo do aluno"
  type        = string
  default     = "Weslley Lucas Souza Alves"
}

variable "ra" {
  description = "RA do aluno, prefixo dos recursos"
  type        = string
  default     = "6325226"
}

variable "vpc_cidr" {
  description = "CIDR da VPC da Aula 12 (não conflita com as Aulas 10/11)"
  type        = string
  default     = "10.12.0.0/16"
}

variable "subnet_cidr" {
  description = "CIDR da subnet pública"
  type        = string
  default     = "10.12.1.0/24"
}

variable "instance_type" {
  description = "Tipo da EC2 da API"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "Key pair do deploy (criado na Aula 10)"
  type        = string
  default     = "technova-aula10-deploy"
}

variable "ssh_cidr_blocks" {
  # ai-review-ignore: runners do GitHub Actions não têm IP fixo; SSH só com a chave do deploy
  description = "Origens liberadas para SSH"
  type        = list(string)
  default     = ["0.0.0.0/0"] # ai-review-ignore: ver README (SSM seria o ideal)
}

variable "alert_email" {
  description = "E-mail inscrito no tópico SNS (vazio = sem inscrição; a confirmação chega por e-mail)"
  type        = string
  default     = ""
}

variable "latency_threshold_ms" {
  description = "Limite fixo do alarme de latência média (ms)"
  type        = number
  default     = 1000
}

variable "error5xx_threshold" {
  description = "Limite fixo de erros 5xx por minuto"
  type        = number
  default     = 10
}

variable "anomaly_band_width" {
  description = "Largura da banda de anomalia em desvios-padrão"
  type        = number
  default     = 2
}

variable "use_bedrock" {
  description = "A Lambda tenta o Bedrock antes da análise por regras (o Lab da turma não tem acesso ao Bedrock)"
  type        = bool
  default     = false
}
