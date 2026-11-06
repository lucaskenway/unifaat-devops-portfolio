# =============================================================
# SECURITY GROUPS — ALB público; EC2 só recebe a porta da app
# vinda do ALB (referência por SG, não por CIDR)
# =============================================================

resource "aws_security_group" "alb" {
  name        = "${local.prefix}-alb-sg"
  description = "ALB da TechNova API (Aula 11): HTTP/HTTPS da internet"
  vpc_id      = aws_vpc.main.id

  tags = { Name = "${local.prefix}-alb-sg" }
}

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = "0.0.0.0/0" # ai-review-ignore: ALB público, ponto de entrada da API
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  description       = "HTTP publico"
}

resource "aws_vpc_security_group_ingress_rule" "alb_https" {
  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = "0.0.0.0/0" # ai-review-ignore: ALB público (listener 443 exige certificado ACM)
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  description       = "HTTPS publico"
}

resource "aws_vpc_security_group_egress_rule" "alb_to_ec2" {
  security_group_id            = aws_security_group.alb.id
  referenced_security_group_id = aws_security_group.ec2.id
  from_port                    = var.app_port
  to_port                      = var.app_port
  ip_protocol                  = "tcp"
  description                  = "Encaminhamento e health check para as EC2"
}

resource "aws_security_group" "ec2" {
  name        = "${local.prefix}-ec2-sg"
  description = "EC2 Blue/Green (Aula 11): app so via ALB, SSH para o deploy"
  vpc_id      = aws_vpc.main.id

  tags = { Name = "${local.prefix}-ec2-sg" }
}

resource "aws_vpc_security_group_ingress_rule" "ec2_from_alb" {
  security_group_id            = aws_security_group.ec2.id
  referenced_security_group_id = aws_security_group.alb.id
  from_port                    = var.app_port
  to_port                      = var.app_port
  ip_protocol                  = "tcp"
  description                  = "TechNova API apenas a partir do ALB"
}

resource "aws_vpc_security_group_ingress_rule" "ec2_ssh" {
  for_each = toset(var.ssh_cidr_blocks)

  security_group_id = aws_security_group.ec2.id
  cidr_ipv4         = each.value # ai-review-ignore: ver variables.tf (ssh_cidr_blocks)
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  description       = "SSH do deploy (GitHub Actions)"
}

resource "aws_vpc_security_group_egress_rule" "ec2_all" {
  security_group_id = aws_security_group.ec2.id
  cidr_ipv4         = "0.0.0.0/0" # ai-review-ignore: saída (egress), necessária para o pull no ECR
  ip_protocol       = "-1"
  description       = "Saida liberada (pull no ECR, pacotes)"
}
