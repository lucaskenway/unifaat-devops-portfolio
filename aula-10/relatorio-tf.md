# Relatório de Produção de TF
**Análise e Desenvolvimento de Sistemas**  
**2026.2**

* **Professor:** Alexandre da Costa Tavares Jr
* **Disciplina:** DevOps
* **Aluno:** Weslley Lucas Souza Alves (RA: 6325226)
* **Aula:** 1☐ 2☐ 3☐ 4☐ 5☐ 6☐ 7☐ 8☐ 9☐ 10☒ 11☐ 12☐ 13☐ 14☐ 15☐
* **Data da aula:** 2026-10-22
* **Título da aula:** Terraform Automatizado e CD Pipelines (ECR / Learner Lab)

---

## Resumo da Atividade Aplicada

### Objetivo
Demonstrar domínio de GitOps para Terraform (plan automático em PRs e apply automático no merge) e de Continuous Deployment, construindo um pipeline unificado CI → Build → Push (**Amazon ECR**) → Deploy que atualiza automaticamente a aplicação na EC2, usando o AWS Academy Learner Lab.

### Tarefa
Implementar, para o repositório `technova-api`, dois fluxos automatizados: (1) **Terraform GitOps** — workflow `terraform-plan.yml` que posta o plan como comentário no PR e workflow `terraform-apply.yml` que aplica no merge para `main`, autenticando na AWS com as credenciais temporárias de sessão do Learner Lab como GitHub Secrets (`us-east-1`); e (2) **Pipeline CD** — `cd.yml` com lint → test → build → push no **Amazon ECR** → deploy via SSH na EC2 pela estratégia Recreate (login no ECR antes do `docker pull`), com health check pós-deploy e rollback manual documentado. Em produção fora do Lab, a autenticação seria substituída por OIDC + role IAM (padrão ideal, indisponível no Lab). Comprovar com screenshots (plan no PR, apply após merge, pipeline CD verde e health check passando).

---

## O que foi produzido

| Requisito | Entrega | Onde |
|-----------|---------|------|
| Plan on PR (15%) | Dispara em PR para `main` quando `aula-10/terraform/**` muda; fmt → init → validate → plan; comentário formatado com tabela de etapas, resumo e plan completo; falha se fmt/plan falharem | `.github/workflows/terraform-plan.yml` |
| Apply on merge (15%) | Push na `main` com `.tf` alterado → init → `apply -auto-approve`; outputs no log e no summary; applies enfileirados (`concurrency`) | `.github/workflows/terraform-apply.yml` |
| Autenticação no Lab (10%) | `configure-aws-credentials@v4` com os 3 secrets de sessão; OIDC documentado como ideal de produção | todos os workflows + `gitops-cd-analise.md` §2 |
| Pipeline CD (15%) | lint → test → build-push (`amazon-ecr-login@v2`, Dockerfile multi-stage, tags `sha-XXXXXXX` + `latest`) → deploy | `.github/workflows/cd.yml` |
| Deploy Recreate (10%) | `appleboy/ssh-action`: login ECR → stop → rm → pull → run, com `GITHUB_SHA`/`DEPLOY_TIME` no container | job `deploy` |
| Health check (10%) | 20 tentativas × 5 s em `/health`; falha o pipeline sem HTTP 200; confere `/version` = commit implantado | job `deploy` |
| Infra | VPC + subnet pública + IGW + SG (regras separadas) + EC2 AL2023 com Docker e LabInstanceProfile; state remoto S3/DynamoDB | `aula-10/terraform/` |
| Documentação (10%) | GitOps, auth Lab vs OIDC, Recreate, Delivery vs Deployment, rollback, limitações | `gitops-cd-analise.md` |
| Runbook (5%) | Procedimento passo a passo com login no ECR antes do pull e `git revert` | `docs/runbook-rollback.md` |

### Bônus
Gate de destroy (label `allow-destroy`), comentário do plan atualizado sem duplicar, `fmt -check`, `GITHUB_SHA` no deploy com verificação via `/version`, notificação por comentário no commit, workflow de destroy manual com environment protegido, environment `production`.

## Decisões

- **Workflows na raiz** (`.github/workflows/`), pois o GitHub não executa workflows em subpastas; `aula-10/.github/workflows/` guarda uma cópia de referência com a estrutura do enunciado.
- **Key pair criado no bootstrap** (`technova-aula10-deploy`) em vez de `aws_key_pair` com `file()`: o apply roda no CI, onde não existe chave local; a chave privada só existe na máquina do aluno e no secret `EC2_SSH_KEY`.
- **Descoberta do IP pela tag** quando `EC2_HOST` não está definido, porque o IP público muda a cada reinício da sessão do Lab.
- **Deploy pela tag imutável `sha-XXXXXXX`**, não `latest`: o que roda é o que foi testado, e o rollback é trocar a tag.
- **`workflow_run`** liga o apply ao CD: quando a infra muda (ex.: EC2 recriada), a app é reimplantada.

## Limitações

Credenciais do Lab expiram (~4 h) e precisam ser atualizadas nos secrets; SSH aberto para `0.0.0.0/0` por falta de IP fixo dos runners; Recreate tem downtime. Detalhes e melhorias em `gitops-cd-analise.md` §6.
