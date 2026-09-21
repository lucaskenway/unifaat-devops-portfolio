# outputs.tf — modules/rds

output "db_endpoint" {
  description = "Endpoint de conexão da instância RDS"
  value       = aws_db_instance.this.endpoint
}

output "db_name" {
  description = "Nome do database"
  value       = aws_db_instance.this.db_name
}

output "db_port" {
  description = "Porta da instância RDS"
  value       = aws_db_instance.this.port
}
