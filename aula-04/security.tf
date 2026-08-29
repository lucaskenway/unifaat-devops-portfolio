# =============================================================
# SECURITY GROUPS
# =============================================================

# Security Group da API (EC2 na subnet pública)
resource "aws_security_group" "api" {
  name        = "${local.prefix}-api-sg"
  description = "Allows SSH (22) and Node.js API (3000) for the TechNova instance"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "API Node.js"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, { Name = "${local.prefix}-api-sg" })
}

# Security Group do banco de dados (futuro) — acesso apenas de dentro da VPC
resource "aws_security_group" "db" {
  name        = "${local.prefix}-db-sg"
  description = "Allows PostgreSQL (5432) only from inside the VPC"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "PostgreSQL from VPC"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, { Name = "${local.prefix}-db-sg" })
}
