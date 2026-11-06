# =============================================================
# TARGET GROUPS — Blue e Green, cada um com a sua EC2.
# O health check usa o readiness (/health/ready): o target só
# entra em serviço quando a API consegue servir pedidos.
# =============================================================

resource "aws_lb_target_group" "app" {
  for_each = local.colors

  name     = "${local.short}-${each.key}"
  port     = var.app_port
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  # Padrão é 300s; 30s deixa o switch e o rollback rápidos (conexões em andamento
  # no ambiente antigo têm 30s para terminar)
  deregistration_delay = 30

  health_check {
    path                = var.health_check_path
    matcher             = "200"
    interval            = 10
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name  = "${local.short}-${each.key}"
    Color = each.key
  }
}

resource "aws_lb_target_group_attachment" "app" {
  for_each = local.colors

  target_group_arn = aws_lb_target_group.app[each.key].arn
  target_id        = aws_instance.app[each.key].id
  port             = var.app_port
}
