output "alb_dns_name" {
  description = "DNS público do ALB (ponto de entrada da TechNova API)"
  value       = aws_lb.main.dns_name
}

output "listener_arn" {
  description = "ARN do listener HTTP:80 (alvo do traffic switch)"
  value       = aws_lb_listener.http.arn
}

output "blue_tg_arn" {
  description = "ARN do Target Group Blue"
  value       = aws_lb_target_group.app["blue"].arn
}

output "green_tg_arn" {
  description = "ARN do Target Group Green"
  value       = aws_lb_target_group.app["green"].arn
}

output "instance_public_ips" {
  description = "IP público de cada EC2 (usado só para o SSH do deploy)"
  value       = { for color, i in aws_instance.app : color => i.public_ip }
}

output "instance_ids" {
  description = "ID de cada EC2"
  value       = { for color, i in aws_instance.app : color => i.id }
}

output "ecr_repository_url" {
  description = "URL do repositório ECR de onde as EC2 fazem o pull"
  value       = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${var.ecr_repository}"
}
