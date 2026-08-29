# =============================================================
# IAM — Instance Profile para a EC2 (sem access keys)
# =============================================================
#
# O AWS Academy Learner Lab bloqueia iam:CreateRole / iam:AttachRolePolicy
# para o role assumido pelo aluno (voclabs) — apenas o role gerenciado pela
# Academy (LabRole, exposto via LabInstanceProfile) pode ser anexado a
# recursos. Por isso reaproveitamos o Instance Profile já existente na
# conta em vez de criar um novo aws_iam_role/aws_iam_instance_profile.
# O LabRole já inclui permissões de leitura de S3 entre suas policies.

data "aws_iam_instance_profile" "lab" {
  name = "LabInstanceProfile"
}
