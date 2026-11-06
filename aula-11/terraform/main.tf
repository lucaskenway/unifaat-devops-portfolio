locals {
  prefix = "${var.ra}-technova-aula11"
  # Nomes de ALB e Target Group têm no máximo 32 caracteres
  short = "${var.ra}-a11"

  colors = toset(["blue", "green"])

  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Owner       = var.ra
    Aluno       = var.aluno
    Aula        = "11"
  }
}

# =============================================================
# REDE — VPC com duas subnets públicas em AZs diferentes
# (requisito do ALB); as EC2 ficam na primeira
# =============================================================

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = { Name = "${local.prefix}-vpc" }
}

resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidrs)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = { Name = "${local.prefix}-public-${var.availability_zones[count.index]}" }
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
  count = length(aws_subnet.public)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# =============================================================
# EC2 — uma instância por cor, ambas com Docker e o mesmo
# LabInstanceProfile (o Lab não permite criar roles IAM)
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

data "aws_iam_instance_profile" "lab" {
  name = "LabInstanceProfile"
}

resource "aws_instance" "app" {
  for_each = local.colors

  ami                    = data.aws_ami.al2023.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public[0].id
  vpc_security_group_ids = [aws_security_group.ec2.id]
  key_name               = var.key_name
  iam_instance_profile   = data.aws_iam_instance_profile.lab.name
  user_data              = file("${path.module}/user_data.sh")

  # O AMI "most_recent" muda com o tempo; sem isso todo plan proporia recriar as EC2
  lifecycle {
    ignore_changes = [ami]
  }

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  # A tag Color é como o workflow encontra a instância ociosa
  tags = {
    Name  = "${local.prefix}-${each.key}"
    Color = each.key
  }
}

data "aws_caller_identity" "current" {}
