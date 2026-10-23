# Runbook: Rollback de Deploy — TechNova API (Aula 10)

## Quando usar

- O health check passou, mas uma funcionalidade quebrou em produção
- Bug crítico detectado depois do deploy
- O pipeline CD falhou no health check e a app ficou fora do ar (estratégia Recreate)

## Pré-requisitos

- Sessão do Learner Lab ativa e credenciais em `~/.aws/credentials` (AWS Details → AWS CLI)
- Chave `~/.ssh/technova-aula10-deploy.pem` (criada por `aula-10/scripts/bootstrap-backend.sh`)
- IP atual da EC2 (muda quando o Lab reinicia a instância):

```bash
aws ec2 describe-instances --region us-east-1 \
  --filters "Name=tag:Name,Values=6325226-technova-aula10-api" "Name=instance-state-name,Values=running" \
  --query 'Reservations[0].Instances[0].PublicIpAddress' --output text
```

## Procedimento

### 1. Identificar a última versão estável

Cada deploy publica `sha-<commit curto>` no ECR. Liste as tags mais recentes:

```bash
aws ecr describe-images --repository-name technova-api --region us-east-1 \
  --query 'sort_by(imageDetails,&imagePushedAt)[-10:].[imagePushedAt,join(`,`,imageTags)]' \
  --output table

git log --oneline -10    # mapear o SHA ao commit
```

Também dá para ver no console: **Amazon ECR → Repositories → technova-api**, ou no comentário de deploy de cada commit na `main`.

### 2. Conectar na EC2

```bash
ssh -i ~/.ssh/technova-aula10-deploy.pem ec2-user@<EC2_IP>
```

### 3. Login no ECR (sempre ANTES do pull)

O token do ECR expira em ~12 h e o pull sem login falha com `no basic auth credentials`.
A EC2 usa o LabInstanceProfile, então a AWS CLI já tem credenciais:

```bash
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGISTRY="${ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com"
aws ecr get-login-password --region us-east-1 \
  | docker login --username AWS --password-stdin "$REGISTRY"
```

### 4. Trocar o container (Recreate)

```bash
TAG=sha-abc1234        # versão estável escolhida no passo 1

docker pull "$REGISTRY/technova-api:$TAG"    # pull antes do stop: menos downtime
docker stop technova-api || true
docker rm technova-api || true
docker run -d --name technova-api \
  -p 3000:3000 \
  --restart unless-stopped \
  -e NODE_ENV=production \
  -e GITHUB_SHA="rollback-$TAG" \
  -e DEPLOY_TIME="$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  "$REGISTRY/technova-api:$TAG"
```

### 5. Verificar

```bash
curl -s http://localhost:3000/health     # {"status":"ok",...}
curl -s http://localhost:3000/version    # commit "rollback-sha-..."
docker logs --tail 50 technova-api
```

E de fora: `curl http://<EC2_IP>:3000/health`.

### 6. Corrigir na main

O rollback só vale até o próximo push na `main`, que reimplanta o código atual. Reverta o commit problemático para o pipeline voltar a implantar uma versão boa:

```bash
git revert <sha-do-commit-ruim>
git push origin main        # o cd.yml implanta a versão revertida
```

### 7. Comunicar

Avisar o time com: versão revertida, versão em produção agora, horário, causa conhecida e link da execução do pipeline.

## Teste do procedimento

| Data | De → para | Resultado |
|------|-----------|-----------|
| _(preencher ao executar no Lab)_ | `sha-novo` → `sha-anterior` | `/version` voltou ao commit anterior, `/health` 200 |
