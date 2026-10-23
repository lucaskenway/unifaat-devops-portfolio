# Aula 09 — Docker Registry e IA no CI/CD

[![CI Pipeline — Aula 09](https://github.com/lucaskenway/unifaat-devops-portfolio/actions/workflows/ci-aula09.yml/badge.svg)](https://github.com/lucaskenway/unifaat-devops-portfolio/actions/workflows/ci-aula09.yml)
[![AI Code Review — Aula 09](https://github.com/lucaskenway/unifaat-devops-portfolio/actions/workflows/ai-review-aula09.yml/badge.svg)](https://github.com/lucaskenway/unifaat-devops-portfolio/actions/workflows/ai-review-aula09.yml)
[![Security Scan — Aula 09](https://github.com/lucaskenway/unifaat-devops-portfolio/actions/workflows/security-scan-aula09.yml/badge.svg)](https://github.com/lucaskenway/unifaat-devops-portfolio/actions/workflows/security-scan-aula09.yml)

Pipeline da **TechNova API**: lint → test → build → push para o **Amazon ECR** (AWS Academy Learner Lab, `us-east-1`), com **AI Code Review** em todo Pull Request e quality gate que bloqueia achados CRITICAL.

Imagem: `<ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/technova-api` (repositório privado, scan on push + lifecycle policy)

## Estrutura

O GitHub só executa workflows de `.github/workflows/` na **raiz** do repositório, por isso workflows e script ficam lá:

```
.github/
├── workflows/
│   ├── ci-aula09.yml             # CI: lint → test → build (+ push ECR com a sessão do Lab)
│   ├── ai-review-aula09.yml      # AI review em PRs + quality gate
│   └── security-scan-aula09.yml  # npm audit + Trivy (Dockerfile e imagem)
└── scripts/
    └── ai-review.js              # análise do diff (20 regras)
aula-09/
├── .github/                      # cópia de referência com os nomes do enunciado (não é executada)
│   ├── workflows/{ci,ai-review,security-scan}.yml
│   └── scripts/ai-review.js
├── technova-api/
│   ├── ecr-push.sh               # fluxo principal: garante repo, login, build e push no ECR
│   ├── ecr-rollback.sh           # pull de uma tag do ECR + troca do container (rollback)
│   ├── ecr-lifecycle-policy.json # expira untagged e mantém os 15 builds sha- mais recentes
│   ├── Dockerfile                # multi-stage, não-root, HEALTHCHECK
│   ├── .dockerignore
│   ├── server.js
│   ├── __tests__/server.test.js
│   └── package.json
├── ia-cicd-analise.md            # estratégia de tagging, regras, prompt, limitações
├── relatorio-tf.md               # relatório de produção do TF
├── screenshots/
└── README.md
```

## Amazon ECR (fluxo principal)

O Learner Lab só dá credenciais **temporárias** e não permite criar IAM, então o push confiável é o script local:

```bash
# 1. Learner Lab → Start Lab → AWS Details → AWS CLI: colar o bloco em ~/.aws/credentials
export AWS_DEFAULT_REGION=us-east-1
aws sts get-caller-identity

# 2. Build + push (sha-XXXXXXX + latest)
cd aula-09/technova-api
./ecr-push.sh

# 3. Release semver (1.0.0, 1.0, 1 + sha + latest)
git tag v1.0.0 -m "Release 1.0.0" && ./ecr-push.sh      # ou: ./ecr-push.sh 1.0.0

# 4. Conferir as tags
aws ecr describe-images --repository-name technova-api --region us-east-1 \
  --query "imageDetails[].imageTags" --output table

# 5. Pull + execução + rollback por tag
./ecr-rollback.sh 1.0.0
./ecr-rollback.sh sha-XXXXXXX
```

O `ecr-push.sh` valida a sessão, cria o repositório se não existir, habilita **scan on push**, aplica a **lifecycle policy**, faz login (`aws ecr get-login-password | docker login --username AWS`), builda e publica todas as tags.

| Comando | Tags publicadas |
|---------|-----------------|
| `./ecr-push.sh` | `sha-XXXXXXX`, `latest` |
| `./ecr-push.sh` com HEAD na tag `v1.2.3`, ou `./ecr-push.sh 1.2.3` | `1.2.3`, `1.2`, `1`, `sha-XXXXXXX`, `latest` |

## Pipelines

### CI — `ci-aula09.yml`

```
lint (ESLint) → test (Jest + coverage) → build-and-push
                                          ├─ build (Buildx + cache gha)
                                          ├─ smoke test (/health)
                                          └─ push Amazon ECR   ← só em push main / tag v*.*.*
                                                                 e com sessão do Lab válida
```

| Evento | Publica? | Tags |
|--------|:--------:|------|
| push na `main` | ✅* | `sha-XXXXXXX`, `latest` |
| tag `v1.2.3` | ✅* | `1.2.3`, `1.2`, `1`, `sha-XXXXXXX` |
| pull request | ❌ | só build + smoke test |

\* Usa os secrets `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` e `AWS_SESSION_TOKEN` com os valores da sessão atual do Lab (`aws-actions/configure-aws-credentials@v4` + `aws-actions/amazon-ecr-login@v2`). Se estiverem ausentes ou expirados, o job registra um aviso e pula o push. O build e o smoke test continuam valendo.

### AI Code Review — `ai-review-aula09.yml`

Dispara em `pull_request` (`opened`, `synchronize`, `reopened`): coleta o diff `base...head`, roda `.github/scripts/ai-review.js` e posta um comentário com tabela por severidade. Em novos pushes no PR o comentário é **atualizado** em vez de duplicado. Se houver **CRITICAL**, o job falha e o PR fica bloqueado.

Detecta 20 padrões: secrets hardcoded, AWS keys, chaves privadas, `eval()`, `new Function()`, SQL injection, command injection, TLS desabilitado, XSS, CORS `*`, bind em `0.0.0.0`, CIDR `0.0.0.0/0`, `console.log`, catch vazio, `debugger`, `FROM :latest`, `USER root`, `chmod 777`, TODO/FIXME e `var`. Detalhes em [ia-cicd-analise.md](ia-cicd-analise.md).

**Camada opcional de LLM (Amazon Bedrock):** com a variável de repositório `BEDROCK_MODEL_ID` e os secrets da sessão do Lab, o mesmo script também envia o diff ao Bedrock (Converse API) e acrescenta uma seção consultiva "🧠 Análise do LLM" ao comentário. Ela não aciona o gate. Sem acesso ao Bedrock, o review continua só com as regras. No Learner Lab testado, os modelos liberados estão descontinuados e os atuais dão `AccessDenied`; os detalhes estão em [ia-cicd-analise.md](ia-cicd-analise.md#3-lógica-de-análise-e-o-prompt-para-ia).

### Security Scan — `security-scan-aula09.yml`

`npm audit` (dependências de produção), Trivy config (Dockerfile) e Trivy image (falha em CRITICAL).

## Executar localmente

```bash
cd aula-09/technova-api
npm ci
npm run lint
npm run test:ci

docker build -t technova-api:local .
docker run -d --name technova -p 3000:3000 technova-api:local
curl http://localhost:3000/health
docker rm -f technova
```

Imagem publicada (com a sessão do Lab ativa):

```bash
ECR_URI=$(aws sts get-caller-identity --query Account --output text).dkr.ecr.us-east-1.amazonaws.com/technova-api
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin "${ECR_URI%%/*}"
docker pull "$ECR_URI:latest"
docker run -p 3000:3000 "$ECR_URI:latest"
```

AI review sobre um diff local (sem GitHub):

```bash
git diff main...HEAD > /tmp/pr-diff.txt
DIFF_FILE=/tmp/pr-diff.txt REVIEW_OUTPUT=/tmp/review.md FAIL_ON_CRITICAL=true \
  node .github/scripts/ai-review.js
```

## Testar o quality gate (PR com problema CRITICAL)

```bash
git checkout -b demo/ai-review-critical
cat > aula-09/technova-api/demo-inseguro.js <<'EOF'
const dbPassword = 'SuperSenha123';
const db = require('./db');

module.exports = (req) => {
  console.log('debug', req.query);
  try {
    return db.query('SELECT * FROM orders WHERE id = ' + req.query.id);
  } catch (e) {}
  return eval(req.query.expr);
};
EOF
git add aula-09/technova-api/demo-inseguro.js
git commit -m "test(aula-09): PR com codigo inseguro para validar o AI review"
git push -u origin demo/ai-review-critical
# abrir PR para main → comentário com 3 CRITICAL / 2 WARNING e check "AI Review" vermelho
```

O PR de demonstração **não deve ser mergeado**: feche-o depois dos screenshots.

Para o check bloquear o botão de merge: *Settings → Branches → Add rule (main) → Require status checks to pass → `AI Review`*.

## Screenshots

| Arquivo | Evidência |
|---------|-----------|
| `screenshots/ecr-console.png` | Repositório `technova-api` no console do ECR com as tags `sha-`, `latest` e semver |
| `screenshots/ecr-push-ok.png` | Execução do `ecr-push.sh` concluída |
| `screenshots/ai-review-comment.png` | Comentário do AI review no PR com os achados |
| `screenshots/quality-gate-block.png` | PR com check `AI Review` falhando por CRITICAL |
