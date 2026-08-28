output "users" {
  description = "Nomes dos usuários IAM criados"
  value = [
    aws_iam_user.juliana_dev.name,
    aws_iam_user.rafael_platform.name,
    aws_iam_user.lucas_intern.name,
  ]
}

output "groups" {
  description = "Nomes dos grupos IAM criados"
  value = [
    aws_iam_group.developers.name,
    aws_iam_group.platform_eng.name,
  ]
}

output "policy_arns" {
  description = "ARNs das custom policies criadas"
  value = {
    s3_read          = aws_iam_policy.s3_read.arn
    ec2_s3_full      = aws_iam_policy.ec2_s3_full.arn
    deny_destructive = aws_iam_policy.deny_destructive.arn
  }
}

output "role_arn" {
  description = "ARN do service role de EC2"
  value       = aws_iam_role.technova_ec2_role.arn
}

output "instance_profile_name" {
  description = "Nome do instance profile vinculado ao service role"
  value       = aws_iam_instance_profile.technova_ec2_profile.name
}
