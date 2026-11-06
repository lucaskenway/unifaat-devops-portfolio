#!/bin/bash
# EC2 da Aula 12: Docker + env file da aplicação (feature flags e métricas)
set -euxo pipefail

dnf update -y
dnf install -y docker jq
systemctl enable --now docker
usermod -aG docker ec2-user

# Lido pelo docker run (--env-file). Trocar uma flag aqui + scripts/toggle-flag.sh
# muda o comportamento da API sem nova imagem.
cat > /home/ec2-user/technova.env <<'ENV'
NODE_ENV=production
PORT=3000
AWS_REGION=us-east-1
METRICS_ENABLED=true
FF_NEW_SHIPPING_CALC=true
FF_BULK_ORDERS=false
FF_AI_RECOMMENDATIONS=false
FF_NEW_CHECKOUT=false
ENV
chown ec2-user:ec2-user /home/ec2-user/technova.env
chmod 600 /home/ec2-user/technova.env
