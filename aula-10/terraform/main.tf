locals {
  prefix = "${var.ra}-technova-aula10"

  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform-GitOps"
    Owner       = var.ra
    Aluno       = var.aluno
    Aula        = "10"
  }
}

# =============================================================
# REDE — VPC com uma subnet pública (a EC2 precisa de IP público
# para receber o SSH do runner e o health check do pipeline)
# =============================================================

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = { Name = "${local.prefix}-vpc" }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true

  tags = { Name = "${local.prefix}-public-subnet" }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = { Name = "${local.prefix}-igw" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0" # ai-review-ignore: rota default para o IGW, não é regra de entrada
    gateway_id = aws_internet_gateway.main.id
  }

  tags = { Name = "${local.prefix}-public-rt" }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# =============================================================
# SECURITY GROUP — regras separadas (aws_security_group_rule)
# para que cada mudança apareça isolada no plan do PR
# =============================================================

resource "aws_security_group" "technova_api" {
  name        = "${local.prefix}-api-sg"
  description = "TechNova API (Aula 10): SSH for the CD pipeline and the API port"
  vpc_id      = aws_vpc.main.id

  tags = { Name = "${local.prefix}-api-sg" }
}

resource "aws_security_group_rule" "ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = var.ssh_cidr_blocks
  security_group_id = aws_security_group.technova_api.id
  description       = "SSH (deploy via appleboy/ssh-action)"
}

resource "aws_security_group_rule" "api" {
  type              = "ingress"
  from_port         = var.app_port
  to_port           = var.app_port
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"] # ai-review-ignore: API pública + health check do runner
  security_group_id = aws_security_group.technova_api.id
  description       = "TechNova API (health check do pipeline)"
}

resource "aws_security_group_rule" "egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"] # ai-review-ignore: saída (egress), necessária para o pull no ECR
  security_group_id = aws_security_group.technova_api.id
  description       = "Saida liberada (pull no ECR, pacotes)"
}

# =============================================================
# EC2 — Amazon Linux 2023 com Docker, recebendo os deploys
# =============================================================

data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# O Lab não permite criar roles IAM; o LabInstanceProfile (LabRole) já existe na conta
# e dá à EC2 permissão de pull no ECR mesmo sem credenciais passadas pelo pipeline
data "aws_iam_instance_profile" "lab" {
  name = "LabInstanceProfile"
}

resource "aws_instance" "api" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.technova_api.id]
  key_name               = var.key_name
  iam_instance_profile   = data.aws_iam_instance_profile.lab.name
  user_data              = file("${path.module}/user_data.sh")

  # O AMI "most_recent" muda com o tempo; sem isso todo plan proporia recriar a EC2
  lifecycle {
    ignore_changes = [ami]
  }

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  tags = { Name = "${local.prefix}-api" }
}

# =============================================================
# ECR — o repositório technova-api pertence ao pipeline da app
# (bootstrap-backend.sh / cd.yml); aqui só montamos a URL
# =============================================================

data "aws_caller_identity" "current" {}
