#!/usr/bin/env bash
# Deploy/rollback simulado: pull de uma tag do ECR e troca do container em execução
#
# Uso:
#   ./ecr-rollback.sh 1.0.0          # sobe (ou volta para) a release 1.0.0
#   ./ecr-rollback.sh sha-a1b2c3d    # volta para um build específico
set -euo pipefail

TAG="${1:?Informe a tag a executar (ex.: 1.0.0 ou sha-a1b2c3d)}"
REGION="${AWS_REGION:-us-east-1}"
REPO="${ECR_REPOSITORY:-technova-api}"
CONTAINER="technova-prod"
PORT="${PORT:-3000}"

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGISTRY="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com"
IMAGE="$REGISTRY/$REPO:$TAG"

echo "==> Login no ECR..."
aws ecr get-login-password --region "$REGION" \
  | docker login --username AWS --password-stdin "$REGISTRY"

# Remove a cópia local para provar que a imagem vem do registry (como numa EC2 nova)
docker rmi "$IMAGE" >/dev/null 2>&1 || true

echo "==> Pull $IMAGE"
docker pull "$IMAGE"

echo "==> Substituindo o container $CONTAINER"
docker rm -f "$CONTAINER" >/dev/null 2>&1 || true
docker run -d --name "$CONTAINER" -p "$PORT:3000" "$IMAGE" >/dev/null

for _ in $(seq 1 15); do
  if curl -sf "http://localhost:$PORT/health"; then
    echo
    echo "✅ $CONTAINER rodando $IMAGE"
    docker inspect --format 'digest: {{index .RepoDigests 0}}' "$IMAGE"
    exit 0
  fi
  sleep 2
done

echo "❌ Health check falhou" >&2
docker logs "$CONTAINER" >&2
exit 1
