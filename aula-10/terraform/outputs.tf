output "ec2_public_ip" {
  description = "IP público da EC2 (valor do secret EC2_HOST)"
  value       = aws_instance.api.public_ip
}

output "ec2_instance_id" {
  description = "ID da instância EC2"
  value       = aws_instance.api.id
}

output "api_url" {
  description = "URL da TechNova API"
  value       = "http://${aws_instance.api.public_ip}:${var.app_port}"
}

output "health_url" {
  description = "Endpoint verificado pelo health check do pipeline CD"
  value       = "http://${aws_instance.api.public_ip}:${var.app_port}/health"
}

output "ssh_command" {
  description = "SSH na EC2 (chave criada pelo bootstrap-backend.sh)"
  value       = "ssh -i ~/.ssh/technova-aula10-deploy.pem ec2-user@${aws_instance.api.public_ip}"
}

output "security_group_id" {
  description = "ID do Security Group da API"
  value       = aws_security_group.technova_api.id
}

output "ecr_repository_url" {
  description = "URL do repositório ECR de onde a EC2 faz o pull"
  value       = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${var.ecr_repository}"
}
