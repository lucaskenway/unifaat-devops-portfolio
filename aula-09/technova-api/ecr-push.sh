#!/usr/bin/env bash
# Build + push da TechNova API para o Amazon ECR (AWS Academy Learner Lab)
#
# Uso:
#   ./ecr-push.sh            # sha-XXXXXXX + latest (+ semver se o HEAD tiver git tag vX.Y.Z)
#   ./ecr-push.sh 1.2.3      # força a release 1.2.3 → tags 1.2.3, 1.2 e 1
#
# Pré-requisito: credenciais da sessão do Lab em ~/.aws/credentials (com aws_session_token)
set -euo pipefail

# ---- Configuração ----
REGION="${AWS_REGION:-us-east-1}"
REPO="${ECR_REPOSITORY:-technova-api}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "==> Validando a sessão do Learner Lab..."
if ! ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text 2>/dev/null); then
  echo "❌ Credenciais inválidas ou expiradas. Reabra o Learner Lab (Start Lab → AWS Details)" >&2
  echo "   e atualize ~/.aws/credentials com o bloco da sessão atual." >&2
  exit 1
fi
REGISTRY="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com"
ECR_URI="$REGISTRY/$REPO"

# Tag pelo SHA curto do commit (rastreabilidade total)
GIT_SHA="$(git rev-parse --short=7 HEAD)"
SHA_TAG="sha-$GIT_SHA"

# Versão: argumento explícito ou git tag vX.Y.Z apontando para o HEAD
VERSION="${1:-}"
if [[ -z "$VERSION" ]]; then
  VERSION="$(git tag --points-at HEAD | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' | sort -V | tail -n1 || true)"
fi
VERSION="${VERSION#v}"

TAGS=("$SHA_TAG" "latest")
if [[ -n "$VERSION" ]]; then
  if [[ ! "$VERSION" =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
    echo "❌ Versão '$VERSION' não é semver (esperado X.Y.Z)" >&2
    exit 1
  fi
  TAGS+=("$VERSION" "${BASH_REMATCH[1]}.${BASH_REMATCH[2]}" "${BASH_REMATCH[1]}")
fi

echo "==> Garantindo o repositório ECR ($REPO em $REGION)..."
if ! aws ecr describe-repositories --repository-names "$REPO" --region "$REGION" >/dev/null 2>&1; then
  aws ecr create-repository \
    --repository-name "$REPO" \
    --region "$REGION" \
    --image-scanning-configuration scanOnPush=true >/dev/null
  echo "    repositório criado"
fi
# Idempotente: garante scan on push e lifecycle policy mesmo em repositório já existente
aws ecr put-image-scanning-configuration --repository-name "$REPO" --region "$REGION" \
  --image-scanning-configuration scanOnPush=true >/dev/null
aws ecr put-lifecycle-policy --repository-name "$REPO" --region "$REGION" \
  --lifecycle-policy-text "file://$SCRIPT_DIR/ecr-lifecycle-policy.json" >/dev/null

echo "==> Login no ECR..."
aws ecr get-login-password --region "$REGION" \
  | docker login --username AWS --password-stdin "$REGISTRY"

echo "==> Build ($SHA_TAG)..."
docker build \
  --label "org.opencontainers.image.revision=$(git rev-parse HEAD)" \
  --label "org.opencontainers.image.version=${VERSION:-$SHA_TAG}" \
  -t "$REPO:local" .

echo "==> Tag e push: ${TAGS[*]}"
for tag in "${TAGS[@]}"; do
  docker tag "$REPO:local" "$ECR_URI:$tag"
  docker push "$ECR_URI:$tag"
done

echo "==> Tags publicadas no ECR:"
aws ecr describe-images --repository-name "$REPO" --region "$REGION" \
  --query "sort_by(imageDetails,&imagePushedAt)[].{Tags:join(', ',imageTags||['<untagged>']),Pushed:imagePushedAt,MB:to_string(imageSizeInBytes)}" \
  --output table

echo
echo "✅ Pronto! Imagem publicada:"
for tag in "${TAGS[@]}"; do
  echo "    $ECR_URI:$tag"
done
