# Aula 10 — Terraform Automatizado (GitOps) e CD Pipeline

[![Terraform Plan — Aula 10](https://github.com/lucaskenway/unifaat-devops-portfolio/actions/workflows/terraform-plan.yml/badge.svg)](https://github.com/lucaskenway/unifaat-devops-portfolio/actions/workflows/terraform-plan.yml)
[![Terraform Apply — Aula 10](https://github.com/lucaskenway/unifaat-devops-portfolio/actions/workflows/terraform-apply.yml/badge.svg)](https://github.com/lucaskenway/unifaat-devops-portfolio/actions/workflows/terraform-apply.yml)
[![CD Pipeline — Aula 10](https://github.com/lucaskenway/unifaat-devops-portfolio/actions/workflows/cd.yml/badge.svg)](https://github.com/lucaskenway/unifaat-devops-portfolio/actions/workflows/cd.yml)

"Nenhum humano executa Terraform diretamente e nenhum deploy é manual."

- **Infra (GitOps):** PR com `.tf` → `terraform plan` comentado no PR → merge → `terraform apply` automático.
- **App (CD):** push na `main` → lint → test → build/push no **Amazon ECR** → deploy Recreate via SSH na EC2 → health check.

Tudo roda no **AWS Academy Learner Lab** (`us-east-1`) com as credenciais temporárias de sessão como GitHub Secrets. Em produção isso seria OIDC + role IAM — ver [`gitops-cd-analise.md`](gitops-cd-analise.md).

## Estrutura

O GitHub só executa workflows de `.github/workflows/` na **raiz** do repositório:

```
.github/workflows/
├── terraform-plan.yml      # PR: fmt → init → validate → plan → comentário (+ gate de destroy)
├── terraform-apply.yml     # push na main: init → apply -auto-approve
├── terraform-destroy.yml   # manual, digitando "destroy" + environment production-destroy
└── cd.yml                  # lint → test → build-push (ECR) → deploy (SSH, Recreate) → health check
aula-10/
├── .github/workflows/      # cópia de referência com a estrutura do enunciado (não é executada)
├── terraform/
│   ├── provider.tf         # provider AWS + backend S3/DynamoDB (bucket via -backend-config)
│   ├── main.tf             # VPC, subnet pública, IGW, Security Group, EC2 (AL2023 + LabInstanceProfile)
│   ├── variables.tf
│   ├── outputs.tf          # IP, URL, health, comando SSH, URL do ECR
│   ├── user_data.sh        # instala Docker na EC2
│   └── .terraform.lock.hcl # versões do provider fixadas (init idêntico no CI)
├── technova-api/           # app Node.js + Dockerfile multi-stage (+ endpoint /version)
├── scripts/bootstrap-backend.sh  # bucket do state + tabela de lock + repo ECR (1x por conta)
├── docs/runbook-rollback.md
├── gitops-cd-analise.md    # análise: GitOps, auth no Lab vs OIDC, Recreate, Delivery vs Deployment
├── relatorio-tf.md
└── screenshots/
```

## Como reproduzir

### 1. Learner Lab

1. **Start Lab** e espere o indicador ficar verde.
2. **AWS Details → AWS CLI: Show** — copie os 3 valores.

3. **Bootstrap (uma vez por conta do Lab)** — com as credenciais em `~/.aws/credentials`:

```bash
./aula-10/scripts/bootstrap-backend.sh
```

Cria, de forma idempotente, o bucket do state `technova-tfstate-<ACCOUNT_ID>` (versionado, criptografado, privado), a tabela de lock `technova-terraform-locks`, o repositório ECR `technova-api` e o key pair `technova-aula10-deploy` (chave privada em `~/.ssh/technova-aula10-deploy.pem`). É o único passo fora do GitOps: o Terraform não consegue criar o backend onde ele mesmo guarda o state. Os workflows montam o nome do bucket a partir do Account ID (`-backend-config`), então nada precisa mudar se o Lab trocar de conta.

### 2. Secrets (Settings → Secrets and variables → Actions)

| Secret | Valor | Obrigatório |
|--------|-------|:-----------:|
| `AWS_ACCESS_KEY_ID` | `aws_access_key_id` da sessão | ✅ |
| `AWS_SECRET_ACCESS_KEY` | `aws_secret_access_key` da sessão | ✅ |
| `AWS_SESSION_TOKEN` | `aws_session_token` da sessão | ✅ |
| `EC2_SSH_KEY` | conteúdo de `~/.ssh/technova-aula10-deploy.pem` (`gh secret set EC2_SSH_KEY < ...`) | ✅ |
| `EC2_USERNAME` | `ec2-user` (padrão se omitido) | — |
| `EC2_HOST` | IP da EC2 (se omitido, descoberto pela tag `Name`) | — |

> ⚠️ As credenciais do Lab **expiram a cada sessão**. Ao reabrir o Lab, atualize os 3 secrets `AWS_*` (`gh secret set AWS_SESSION_TOKEN` etc.), senão os workflows falham com `ExpiredToken`.

Environments (Settings → Environments): `production` (deploy; adicione *required reviewers* para virar Continuous Delivery) e `production-destroy` (com *required reviewers*).

Branch protection da `main`: PR obrigatório + status check **Terraform Plan** obrigatório.

### 3. Fluxo GitOps (infra)

```bash
git checkout -b feat/aula-10-https-sg-rule
# ex.: adicionar aws_security_group_rule "https" (443) em aula-10/terraform/main.tf
git commit -am "feat(aula-10): libera HTTPS no security group da API"
git push -u origin feat/aula-10-https-sg-rule
gh pr create --base main
```

- **Terraform Plan** roda e comenta o plan no PR (o mesmo comentário é atualizado a cada push).
- Merge → **Terraform Apply** aplica e mostra os outputs no summary → dispara o **CD Pipeline** (redeploy).

### 4. Fluxo CD (app)

Qualquer push na `main` em `aula-10/technova-api/**` dispara o `cd.yml`. Conferir:

```bash
IP=$(terraform -chdir=aula-10/terraform output -raw ec2_public_ip)
curl http://$IP:3000/health
curl http://$IP:3000/version   # {"version":"1.1.0","commit":"<GITHUB_SHA>","deployedAt":"..."}
```

### 5. Rollback

[`docs/runbook-rollback.md`](docs/runbook-rollback.md) — login no ECR → stop → rm → run com a tag `sha-XXXXXXX` anterior → `git revert` na main.

### Local (desenvolvimento)

```bash
cd aula-10/technova-api && npm ci && npm run lint && npm test
cd ../terraform && terraform fmt -check && terraform init && terraform plan
```

## Evidências

| Screenshot | O que mostra |
|------------|--------------|
| [`screenshots/plan-pr-comment.png`](screenshots/plan-pr-comment.png) | Plan comentado no PR #5 (infra inicial, 10 to add; comentário *edited* = atualizado, não duplicado) |
| [`screenshots/plan-pr-comment-https.png`](screenshots/plan-pr-comment-https.png) | Plan do PR #8 (regra HTTPS, 1 to add) com o plan completo |
| [`screenshots/apply-success.png`](screenshots/apply-success.png) | Terraform Apply verde após o merge do PR #5 |
| [`screenshots/cd-pipeline-green.png`](screenshots/cd-pipeline-green.png) | CD: lint → test → build-push → deploy verdes |
| [`screenshots/health-check-pass.png`](screenshots/health-check-pass.png) | Log do health check e do `/version` (imagem renderizada do log real do run) |

Execuções:

| O quê | PR / run |
|-------|----------|
| Plan no PR (infra inicial) | [PR #5](https://github.com/lucaskenway/unifaat-devops-portfolio/pull/5) |
| Apply após merge (10 recursos) | [run 39970717413](https://github.com/lucaskenway/unifaat-devops-portfolio/actions/runs/39970717413) |
| CD completo (merge do PR #6) | [run 39971130945](https://github.com/lucaskenway/unifaat-devops-portfolio/actions/runs/39971130945) |
| GitOps end-to-end: plan (1 to add) → apply → CD via `workflow_run` | [PR #8](https://github.com/lucaskenway/unifaat-devops-portfolio/pull/8) · [apply 39972897118](https://github.com/lucaskenway/unifaat-devops-portfolio/actions/runs/39972897118) · [CD 39972962601](https://github.com/lucaskenway/unifaat-devops-portfolio/actions/runs/39972962601) |
| Retorno à main após o teste de rollback | [run 39973365347](https://github.com/lucaskenway/unifaat-devops-portfolio/actions/runs/39973365347) |

No primeiro deploy, a conferência de `/version` falhou o pipeline porque o CI da Aula 09 tinha sobrescrito a tag `sha-XXXXXXX` no ECR ([PR #7](https://github.com/lucaskenway/unifaat-devops-portfolio/pull/7) corrigiu); detalhes em `gitops-cd-analise.md` §6.
