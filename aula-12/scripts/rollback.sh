#!/bin/bash
# scripts/rollback.sh — roda NA EC2: volta o container para a versão anterior (imagem no ECR)
#
# Uso: rollback.sh [container] [registry/repo] [tag_anterior]
# Sem tag, lê o label previous.version que o deploy gravou no container atual.
set -euo pipefail
CONTAINER_NAME=${1:-technova-api}
REGION=${AWS_REGION:-us-east-1}
REPO=${2:-${ECR_URI:-"$(aws sts get-caller-identity --query Account --output text).dkr.ecr.${REGION}.amazonaws.com/technova-api"}}
PREVIOUS_TAG=${3:-}
ENV_FILE=${ENV_FILE:-/home/ec2-user/technova.env}

echo "🔄 ROLLBACK do container $CONTAINER_NAME"

if [ -z "$PREVIOUS_TAG" ]; then
  PREVIOUS_TAG=$(docker inspect --format '{{index .Config.Labels "previous.version"}}' "$CONTAINER_NAME" 2>/dev/null || true)
fi
if [ -z "$PREVIOUS_TAG" ] || [ "$PREVIOUS_TAG" = "<no value>" ]; then
  echo "❌ Versão anterior desconhecida. Informe: rollback.sh <container> <repo> <tag>"
  exit 1
fi
# Commit da versão anterior (label gravado pelo deploy); sem ele, deriva da tag
PREVIOUS_COMMIT=$(docker inspect --format '{{index .Config.Labels "previous.commit"}}' "$CONTAINER_NAME" 2>/dev/null || true)
case "$PREVIOUS_COMMIT" in ""|"<no value>") PREVIOUS_COMMIT=$(echo "$PREVIOUS_TAG" | sed -E 's/^a12-sha-([0-9a-f]+).*/\1/') ;; esac
echo "   Versão alvo: $REPO:$PREVIOUS_TAG (commit $PREVIOUS_COMMIT)"

# Token do ECR expira; login sempre antes do pull
aws ecr get-login-password --region "$REGION" | docker login --username AWS --password-stdin "${REPO%%/*}"
docker pull "$REPO:$PREVIOUS_TAG"

docker rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true
docker run -d --name "$CONTAINER_NAME" \
  -p 3000:3000 --restart unless-stopped \
  --env-file "$ENV_FILE" \
  -e GITHUB_SHA="$PREVIOUS_COMMIT" -e IMAGE_TAG="$PREVIOUS_TAG" \
  -e DEPLOY_TIME="$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --log-driver awslogs --log-opt awslogs-region="$REGION" \
  --log-opt awslogs-group=/technova/api --log-opt awslogs-create-group=true \
  "$REPO:$PREVIOUS_TAG"

for _ in $(seq 1 15); do
  if curl -sf --max-time 3 http://localhost:3000/health >/dev/null; then
    echo "✅ ROLLBACK concluído — rodando $PREVIOUS_TAG"
    curl -s http://localhost:3000/version; echo
    exit 0
  fi
  sleep 2
done
echo "❌ ROLLBACK FALHOU — container não ficou saudável"
docker logs "$CONTAINER_NAME" --tail 20 || true
exit 1
