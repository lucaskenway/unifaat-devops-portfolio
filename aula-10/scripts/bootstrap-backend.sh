#!/usr/bin/env bash
# Bootstrap da Aula 10 — roda UMA vez por conta do Learner Lab, antes do primeiro workflow.
#
# Cria (idempotente) o que o Terraform não pode gerenciar sobre si mesmo:
#   - bucket S3  technova-tfstate-<ACCOUNT_ID>  (state remoto: versionado, criptografado, privado)
#   - tabela DynamoDB technova-terraform-locks  (lock do state)
#   - repositório ECR technova-api               (destino do push do cd.yml, scan on push)
#   - key pair technova-aula10-deploy            (SSH do deploy; a chave privada fica só em
#                                                 ~/.ssh/technova-aula10-deploy.pem → secret EC2_SSH_KEY)
#
# Uso: credenciais do Lab em ~/.aws/credentials (AWS Details → AWS CLI) e depois
#   ./aula-10/scripts/bootstrap-backend.sh
set -euo pipefail

REGION=us-east-1
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
BUCKET="technova-tfstate-${ACCOUNT_ID}"
TABLE=technova-terraform-locks
REPO=technova-api
KEY_NAME=technova-aula10-deploy
KEY_FILE="$HOME/.ssh/${KEY_NAME}.pem"

echo "Conta: $ACCOUNT_ID ($REGION)"

if aws s3api head-bucket --bucket "$BUCKET" 2>/dev/null; then
  echo "✔ bucket $BUCKET já existe"
else
  aws s3api create-bucket --bucket "$BUCKET" --region "$REGION" >/dev/null
  echo "✚ bucket $BUCKET criado"
fi
aws s3api put-bucket-versioning --bucket "$BUCKET" \
  --versioning-configuration Status=Enabled
aws s3api put-bucket-encryption --bucket "$BUCKET" \
  --server-side-encryption-configuration \
  '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"},"BucketKeyEnabled":true}]}'
aws s3api put-public-access-block --bucket "$BUCKET" \
  --public-access-block-configuration \
  BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

if aws dynamodb describe-table --table-name "$TABLE" --region "$REGION" >/dev/null 2>&1; then
  echo "✔ tabela $TABLE já existe"
else
  aws dynamodb create-table --table-name "$TABLE" --region "$REGION" \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST >/dev/null
  aws dynamodb wait table-exists --table-name "$TABLE" --region "$REGION"
  echo "✚ tabela $TABLE criada"
fi

if aws ecr describe-repositories --repository-names "$REPO" --region "$REGION" >/dev/null 2>&1; then
  echo "✔ repositório ECR $REPO já existe"
else
  aws ecr create-repository --repository-name "$REPO" --region "$REGION" \
    --image-scanning-configuration scanOnPush=true >/dev/null
  echo "✚ repositório ECR $REPO criado"
fi

# A chave privada só pode ser baixada na criação; se ela não existe localmente, recria o par
if [ -f "$KEY_FILE" ] && aws ec2 describe-key-pairs --key-names "$KEY_NAME" --region "$REGION" >/dev/null 2>&1; then
  echo "✔ key pair $KEY_NAME já existe ($KEY_FILE)"
else
  aws ec2 delete-key-pair --key-name "$KEY_NAME" --region "$REGION" >/dev/null 2>&1 || true
  mkdir -p "$HOME/.ssh"
  (umask 077; aws ec2 create-key-pair --key-name "$KEY_NAME" --key-type rsa --key-format pem \
    --region "$REGION" --query KeyMaterial --output text > "$KEY_FILE")
  echo "✚ key pair $KEY_NAME criado — chave privada em $KEY_FILE"
fi

echo
echo "Secret do deploy:  gh secret set EC2_SSH_KEY < $KEY_FILE"
echo "Pronto. Init local:"
echo "  terraform -chdir=aula-10/terraform init -backend-config=\"bucket=$BUCKET\""
