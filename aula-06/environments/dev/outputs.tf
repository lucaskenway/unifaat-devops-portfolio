# outputs.tf — environments/dev

output "vpc_id" {
  description = "ID da VPC do ambiente dev"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "IDs das subnets públicas"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs das subnets privadas"
  value       = module.vpc.private_subnet_ids
}

output "api_instance_id" {
  description = "ID da instância EC2 da API"
  value       = module.api_server.instance_id
}

output "api_public_ip" {
  description = "IP público da instância EC2 da API"
  value       = module.api_server.public_ip
}

output "db_endpoint" {
  description = "Endpoint de conexão do RDS"
  value       = module.database.db_endpoint
}
