# -----------------------------------------------------------------------------
# Policy 1: technova-s3-read
# Leitura de objetos e listagem em buckets technova-* — anexada ao grupo developers
# -----------------------------------------------------------------------------

data "aws_iam_policy_document" "s3_read" {
  statement {
    sid    = "TechnovaS3Read"
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:ListBucket",
    ]

    resources = [
      "arn:aws:s3:::technova-*",
      "arn:aws:s3:::technova-*/*",
    ]
  }
}

resource "aws_iam_policy" "s3_read" {
  name        = "${local.prefix}-s3-read"
  path        = "/technova/"
  description = "Permite leitura (GetObject/ListBucket) em buckets technova-*"
  policy      = data.aws_iam_policy_document.s3_read.json
  tags        = local.common_tags
}

resource "aws_iam_group_policy_attachment" "developers_s3_read" {
  group      = aws_iam_group.developers.name
  policy_arn = aws_iam_policy.s3_read.arn
}

# -----------------------------------------------------------------------------
# Policy 2: technova-ec2-s3-full
# EC2 describe + start/stop restrito por tag Project=TechNova, e S3 read/write —
# anexada ao grupo platform-eng
# -----------------------------------------------------------------------------

data "aws_iam_policy_document" "ec2_s3_full" {
  statement {
    sid    = "EC2Describe"
    effect = "Allow"

    actions = [
      "ec2:DescribeInstances",
      "ec2:DescribeInstanceStatus",
      "ec2:DescribeTags",
    ]

    resources = ["*"]
  }

  statement {
    sid    = "EC2StartStopComTag"
    effect = "Allow"

    actions = [
      "ec2:StartInstances",
      "ec2:StopInstances",
    ]

    resources = ["arn:aws:ec2:*:*:instance/*"]

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/Project"
      values   = [var.project_name]
    }
  }

  statement {
    sid    = "S3ReadWrite"
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListBucket",
    ]

    resources = [
      "arn:aws:s3:::technova-*",
      "arn:aws:s3:::technova-*/*",
    ]
  }
}

resource "aws_iam_policy" "ec2_s3_full" {
  name        = "${local.prefix}-ec2-s3-full"
  path        = "/technova/"
  description = "Describe de EC2, start/stop restrito a instancias com tag Project=TechNova, e S3 read/write em buckets technova-*"
  policy      = data.aws_iam_policy_document.ec2_s3_full.json
  tags        = local.common_tags
}

resource "aws_iam_group_policy_attachment" "platform_eng_ec2_s3_full" {
  group      = aws_iam_group.platform_eng.name
  policy_arn = aws_iam_policy.ec2_s3_full.arn
}

# -----------------------------------------------------------------------------
# Policy 3: technova-deny-destructive
# Deny explícito para ações destrutivas — anexada ao grupo developers como
# camada extra de proteção (cobre também o estagiário, que só está nesse grupo)
# -----------------------------------------------------------------------------

data "aws_iam_policy_document" "deny_destructive" {
  statement {
    sid    = "DenyDestructiveActions"
    effect = "Deny"

    actions = [
      "s3:Delete*",
      "ec2:Terminate*",
      "ec2:Delete*",
      "iam:Delete*",
    ]

    resources = ["*"]
  }
}

resource "aws_iam_policy" "deny_destructive" {
  name        = "${local.prefix}-deny-destructive"
  path        = "/technova/"
  description = "Deny explicito para acoes destrutivas (Delete*/Terminate*), independente de qualquer Allow"
  policy      = data.aws_iam_policy_document.deny_destructive.json
  tags        = local.common_tags
}

resource "aws_iam_group_policy_attachment" "developers_deny_destructive" {
  group      = aws_iam_group.developers.name
  policy_arn = aws_iam_policy.deny_destructive.arn
}
