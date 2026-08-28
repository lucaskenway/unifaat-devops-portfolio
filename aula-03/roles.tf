# -----------------------------------------------------------------------------
# Service Role: EC2 -> S3
# Permite que instâncias EC2 assumam o role e leiam/gravem no bucket
# technova-app-data-* usando credenciais temporárias (sem access keys fixas)
# -----------------------------------------------------------------------------

data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    sid     = "EC2AssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "technova_ec2_role" {
  name               = "${local.prefix}-ec2-role"
  path               = "/technova/"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
  tags               = local.common_tags
}

data "aws_iam_policy_document" "ec2_role_permissions" {
  statement {
    sid    = "AppDataReadWrite"
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListBucket",
    ]

    resources = [
      "arn:aws:s3:::technova-app-data-*",
      "arn:aws:s3:::technova-app-data-*/*",
    ]
  }
}

resource "aws_iam_role_policy" "technova_ec2_role_permissions" {
  name   = "${local.prefix}-ec2-role-s3-access"
  role   = aws_iam_role.technova_ec2_role.id
  policy = data.aws_iam_policy_document.ec2_role_permissions.json
}

resource "aws_iam_instance_profile" "technova_ec2_profile" {
  name = "${local.prefix}-ec2-profile"
  role = aws_iam_role.technova_ec2_role.name
  tags = local.common_tags
}
