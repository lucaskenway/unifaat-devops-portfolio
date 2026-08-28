locals {
  prefix = "${var.ra}-technova"

  common_tags = {
    Project    = var.project_name
    ManagedBy  = "Terraform"
    Aluno      = var.aluno
    RA         = var.ra
    Disciplina = "DevOps - UniFAAT 2026-2"
    Aula       = "03"
  }
}

# -----------------------------------------------------------------------------
# Groups
# -----------------------------------------------------------------------------

resource "aws_iam_group" "developers" {
  name = "${local.prefix}-developers"
  path = "/technova/"
}

resource "aws_iam_group" "platform_eng" {
  name = "${local.prefix}-platform-eng"
  path = "/technova/"
}

# -----------------------------------------------------------------------------
# Users
# -----------------------------------------------------------------------------

resource "aws_iam_user" "juliana_dev" {
  name = "${var.ra}-juliana-dev"
  path = "/technova/"
  tags = merge(local.common_tags, { Papel = "Desenvolvedora Senior" })
}

resource "aws_iam_user" "rafael_platform" {
  name = "${var.ra}-rafael-platform"
  path = "/technova/"
  tags = merge(local.common_tags, { Papel = "Desenvolvedor Backend + Platform Eng" })
}

resource "aws_iam_user" "lucas_intern" {
  name = "${var.ra}-lucas-intern"
  path = "/technova/"
  tags = merge(local.common_tags, { Papel = "Estagiario - somente leitura" })
}

# -----------------------------------------------------------------------------
# Memberships
# -----------------------------------------------------------------------------

resource "aws_iam_group_membership" "developers" {
  name  = "${local.prefix}-developers-membership"
  group = aws_iam_group.developers.name

  users = [
    aws_iam_user.juliana_dev.name,
    aws_iam_user.rafael_platform.name,
    aws_iam_user.lucas_intern.name,
  ]
}

resource "aws_iam_group_membership" "platform_eng" {
  name  = "${local.prefix}-platform-eng-membership"
  group = aws_iam_group.platform_eng.name

  users = [
    aws_iam_user.rafael_platform.name,
  ]
}
