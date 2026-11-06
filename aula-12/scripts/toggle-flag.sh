#!/bin/bash
# scripts/toggle-flag.sh — roda NA EC2: liga/desliga uma feature flag SEM redeploy
#
# Uso: toggle-flag.sh FF_NEW_SHIPPING_CALC false
# Edita o env file da aplicação e recria o container com a MESMA imagem que já está
# rodando: sem build, sem push, sem pipeline. (docker restart não relê --env-file,
# por isso o container é recriado — leva ~3 s.)
set -euo pipefail
FLAG=${1:?informe a flag, ex.: FF_NEW_SHIPPING_CALC}
VALUE=${2:?informe true ou false}
CONTAINER_NAME=${CONTAINER_NAME:-technova-api}
ENV_FILE=${ENV_FILE:-/home/ec2-user/technova.env}
REGION=${AWS_REGION:-us-east-1}

case "$FLAG" in FF_*) ;; *) echo "❌ flag deve começar com FF_"; exit 1 ;; esac

if grep -q "^${FLAG}=" "$ENV_FILE"; then
  sed -i "s/^${FLAG}=.*/${FLAG}=${VALUE}/" "$ENV_FILE"
else
  echo "${FLAG}=${VALUE}" >> "$ENV_FILE"
fi

# Reaproveita imagem, labels e variáveis de deploy do container atual
IMAGE=$(docker inspect --format '{{.Config.Image}}' "$CONTAINER_NAME")
PREV=$(docker inspect --format '{{index .Config.Labels "previous.version"}}' "$CONTAINER_NAME")
get_env() { docker inspect --format '{{range .Config.Env}}{{println .}}{{end}}' "$CONTAINER_NAME" | sed -n "s/^$1=//p"; }
SHA=$(get_env GITHUB_SHA); TAG=$(get_env IMAGE_TAG); TIME=$(get_env DEPLOY_TIME)

echo "🚩 ${FLAG}=${VALUE} — recriando $CONTAINER_NAME com a mesma imagem ($IMAGE)"
docker rm -f "$CONTAINER_NAME" >/dev/null
docker run -d --name "$CONTAINER_NAME" \
  -p 3000:3000 --restart unless-stopped \
  --env-file "$ENV_FILE" \
  -e GITHUB_SHA="$SHA" -e IMAGE_TAG="$TAG" -e DEPLOY_TIME="$TIME" \
  --label "previous.version=$PREV" \
  --log-driver awslogs --log-opt awslogs-region="$REGION" \
  --log-opt awslogs-group=/technova/api --log-opt awslogs-create-group=true \
  "$IMAGE" >/dev/null

for _ in $(seq 1 15); do
  curl -sf --max-time 3 http://localhost:3000/health >/dev/null && break
  sleep 1
done
curl -s http://localhost:3000/version; echo
