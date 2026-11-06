#!/bin/bash
# Prepara a EC2 para receber os deploys do pipeline CD:
# Docker (pull/run da imagem) — a AWS CLI v2 já vem no Amazon Linux 2023 (login no ECR)
set -euxo pipefail

dnf update -y
dnf install -y docker
systemctl enable --now docker
usermod -aG docker ec2-user
