# Aula 12 — Rollback Strategies e AIOps

Defesas operacionais da TechNova API no AWS Academy Learner Lab (`us-east-1`):

| Camada | O que faz | Onde |
|---|---|---|
| Feature flags | Liga ou desliga uma feature trocando `FF_*` e reiniciando, sem imagem nova | `src/feature-flags.js`, `routes/flags.js`, `scripts/toggle-flag.sh` |
| Migrações expand-contract | Schema evolui sem travar o rollback da API; `up`/`down`/`verify` transacionais | `migrations/` |
| Rollback automático | Deploy → janela de observação → volta para a imagem anterior do ECR se o `/health` falhar | `.github/workflows/cd-with-rollback.yml` (na raiz do repo), `scripts/` |
| Runbook | Roteiro de incidente com diagnóstico, rollback, flag e escalação | `docs/runbooks/deploy-failed.md` |
| AIOps | Métricas `TechNova/API`, alarmes fixos e anomaly band, alarme composto, dashboard, Lambda `LabRole` disparada pelo EventBridge | `src/metrics.js`, `terraform/aiops.tf`, `lambda-aiops/` |

Análise crítica: [`aiops-analise.md`](aiops-analise.md). Evidências: [`screenshots/`](screenshots/) e `evidencias/` na raiz.

## Estrutura

```
aula-12/
├── server.js                    # API 1.3.0 (+ /flags, injeção de falhas para os testes)
├── routes/{orders,flags}.js     # frete v1/v2 por flag; /flags bloqueado em produção
├── src/feature-flags.js         # FF_* do ambiente, com padrões
├── src/metrics.js               # PutMetricData (ResponseTime, Error5xx/4xx, OrdersCreated/Failed)
├── src/middleware/metrics-middleware.js
├── migrations/                  # 001 e 002 expand-contract, runner.js, cli.js
├── db/init.sql                  # schema base (customers, orders) para testar as migrações
├── scripts/                     # health-check, rollback, toggle-flag, demos
├── lambda-aiops/                # index.js (Lambda), analysis.js (regras/prompt/post-mortem), local-simulator.js
├── docs/runbooks/deploy-failed.md
├── terraform/                   # EC2 + SNS + alarmes + dashboard + Lambda + EventBridge
└── __tests__/                   # Jest: flags, frete, /flags, runner de migrações
```

## Como executar

```bash
cd aula-12
npm ci && npm test                       # 19 testes

# Feature flags (local)
bash scripts/demo-flags.sh               # frete v2 com a flag ligada, v1 com ela desligada

# Migrações (precisa de Docker)
docker compose up -d postgres
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/technova npm run migrate:up
npm run migrate:status
node migrations/cli.js down 001          # reverte só a 002
node migrations/cli.js down 000          # reverte todas
# ou, num host com Docker sem Node: bash scripts/demo-migrations.sh

# Simulador AIOps (sem AWS e sem Bedrock)
node lambda-aiops/local-simulator.js all            # 3 cenários
node lambda-aiops/local-simulator.js 2 --prompt     # imprime o prompt para analisar no Kiro AI
```

### Infra (Learner Lab)

```bash
cd aula-12/terraform
terraform init -backend-config=bucket=technova-tfstate-$(aws sts get-caller-identity --query Account --output text)
terraform apply
```

Lab sem permissão de IAM: a EC2 usa o `LabInstanceProfile` (que dá credenciais para PutMetricData, logs `awslogs` e pull do ECR). A Lambda usa a `LabRole`, lida com `data "aws_iam_role"`. O Lab da turma **não tem Bedrock**, então `use_bedrock = false`: a Lambda usa a análise por regras de `analysis.js`, e a análise por IA foi feita com o Kiro AI usando o mesmo prompt. Detalhes no `aiops-analise.md`.

### Pipeline

Um push na `main` que altera `aula-12/` dispara a sequência: lint/test → build/push `technova-api:a12-sha-<commit>` → deploy por SSH → janela de 6 checks × 10 s, com tolerância de 2 falhas. Se a janela falhar, o `rollback.sh` volta para a `imageTag` que o `/version` reportava antes do deploy. Depois disso, o pipeline publica no SNS e o workflow termina vermelho.

Para testar o rollback: **Actions → CD with Automated Rollback — Aula 12 → Run workflow → `simulate_failure` = true**. A versão nova sobe com `FAIL_HEALTHCHECK=true`, o `/health` responde 503 e o pipeline reverte sozinho.

### Limpeza

```bash
cd aula-12/terraform && terraform destroy
```
