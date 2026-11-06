output "api_public_ip" {
  value = aws_instance.api.public_ip
}

output "api_url" {
  value = "http://${aws_instance.api.public_ip}:3000"
}

output "sns_topic_arn" {
  value = aws_sns_topic.alerts.arn
}

output "lambda_name" {
  value = aws_lambda_function.aiops.function_name
}

output "dashboard_url" {
  value = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${aws_cloudwatch_dashboard.technova.dashboard_name}"
}

output "alarms_url" {
  value = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#alarmsV2:?search=TechNova-"
}
