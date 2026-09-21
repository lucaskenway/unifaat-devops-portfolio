# main.tf — environments/dev
# Composição: VPC → Security Groups → EC2 / RDS

module "vpc" {
  source = "../../modules/vpc"

  vpc_cidr     = var.vpc_cidr
  project_name = var.project_name
  environment  = var.environment
  subnets      = var.subnets
}

# AMI mais recente do Amazon Linux 2023
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

module "api_sg" {
  source = "../../modules/security-group"

  name         = "${var.project_name}-${var.environment}-api-sg"
  vpc_id       = module.vpc.vpc_id # ← Composição: output do VPC
  environment  = var.environment
  project_name = var.project_name

  ingress_rules = [
    { port = 80, cidr = "0.0.0.0/0", description = "HTTP" },
    { port = 22, cidr = "0.0.0.0/0", description = "SSH" },
  ]
}

module "rds_sg" {
  source = "../../modules/security-group"

  name         = "${var.project_name}-${var.environment}-rds-sg"
  vpc_id       = module.vpc.vpc_id # ← Composição: output do VPC
  environment  = var.environment
  project_name = var.project_name

  ingress_rules = [
    { port = 5432, cidr = var.vpc_cidr, description = "PostgreSQL somente da VPC" },
  ]
}

module "api_server" {
  source = "../../modules/ec2"

  instance_name      = "${var.project_name}-${var.environment}-api"
  instance_type      = "t2.micro"
  ami_id             = data.aws_ami.amazon_linux.id
  subnet_id          = module.vpc.public_subnet_ids[0] # ← Composição: output do VPC
  security_group_ids = [module.api_sg.sg_id]           # ← Composição: output do SG
  key_name           = var.key_name
  environment        = var.environment
  project_name       = var.project_name
}

module "database" {
  source = "../../modules/rds"

  db_name            = var.db_name
  db_username        = var.db_username
  db_password        = var.db_password
  subnet_ids         = module.vpc.private_subnet_ids # ← Composição: output do VPC
  security_group_ids = [module.rds_sg.sg_id]         # ← Composição: output do SG
  instance_class     = var.db_instance_class
  environment        = var.environment
  project_name       = var.project_name
}
