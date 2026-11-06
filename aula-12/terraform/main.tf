locals {
  prefix = "${var.ra}-technova-aula12"

  common_tags = {
    Project     = "TechNova"
    Environment = "production"
    ManagedBy   = "Terraform"
    Owner       = var.ra
    Aluno       = var.aluno
    Aula        = "12"
  }
}

data "aws_caller_identity" "current" {}

# =============================================================
# REDE + EC2 da API (Docker; credenciais via LabInstanceProfile)
# =============================================================

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = { Name = "${local.prefix}-vpc" }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet_cidr
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true
  tags                    = { Name = "${local.prefix}-public" }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "${local.prefix}-igw" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0" # ai-review-ignore: rota default para o IGW
    gateway_id = aws_internet_gateway.main.id
  }
  tags = { Name = "${local.prefix}-rt" }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "api" {
  name        = "${local.prefix}-sg"
  description = "TechNova API aula 12: HTTP 3000 e SSH do deploy"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "API"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # ai-review-ignore: API pública do lab
  }

  ingress {
    description = "SSH do pipeline"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.ssh_cidr_blocks
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] # ai-review-ignore: saída para ECR/CloudWatch
  }

  tags = { Name = "${local.prefix}-sg" }
}

data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

data "aws_iam_instance_profile" "lab" {
  name = "LabInstanceProfile"
}

resource "aws_instance" "api" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.api.id]
  key_name               = var.key_name
  iam_instance_profile   = data.aws_iam_instance_profile.lab.name
  user_data              = file("${path.module}/user_data.sh")

  lifecycle {
    ignore_changes = [ami]
  }

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  # O workflow cd-with-rollback.yml encontra a EC2 por esta tag
  tags = { Name = "${local.prefix}-api" }
}
