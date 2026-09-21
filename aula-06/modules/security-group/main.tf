# main.tf — modules/security-group
# Módulo genérico: funciona para qualquer SG (API, RDS, bastion, ...) —
# as regras de ingress são recebidas como lista de objetos.

resource "aws_security_group" "this" {
  name        = var.name
  description = "Security Group gerenciado por Terraform - ${var.name}"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.ingress_rules
    content {
      from_port   = ingress.value.port
      to_port     = ingress.value.port
      protocol    = "tcp"
      cidr_blocks = [ingress.value.cidr]
      description = ingress.value.description
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  tags = {
    Name        = var.name
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}
