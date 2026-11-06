# =============================================================
# ALB + LISTENER — o listener HTTP:80 é a "chave" do Blue/Green:
# trocar o target group do default_action troca 100% do tráfego
# =============================================================

resource "aws_lb" "main" {
  name               = "${local.short}-alb"
  load_balancer_type = "application"
  internal           = false
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id

  tags = { Name = "${local.short}-alb" }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  # Blue é o ambiente ativo na criação
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app["blue"].arn
  }

  # Depois do primeiro apply, quem decide o ambiente ativo é o workflow de deploy
  # (aws elbv2 modify-listener). Sem isso, um terraform apply posterior faria um
  # "rollback" silencioso para Blue.
  lifecycle {
    ignore_changes = [default_action]
  }
}
