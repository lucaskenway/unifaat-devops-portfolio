# Relatório de Produção de TF
**Análise e Desenvolvimento de Sistemas**  
**2026.2**

* **Professor:** Alexandre da Costa Tavares Jr
* **Disciplina:** DevOps
* **Aluno:** Weslley Lucas Souza Alves (RA: 6325226)
* **Aula:** 1☐ 2☐ 3☐ 4☐ 5☐ 6☐ 7☐ 8☐ 9☒ 10☐ 11☐ 12☐ 13☐ 14☐ 15☐
* **Data da aula:** 2026-10-15
* **Título da aula:** Docker Registry (Amazon ECR) e IA no CI/CD

---

## Resumo da Atividade Aplicada

### Objetivo
Demonstrar domínio de publicação de imagens Docker no **Amazon ECR** (usando o AWS Academy Learner Lab) e de integração de IA ao fluxo de code review, construindo um pipeline completo que builda, publica e revisa código automaticamente, com quality gate.

### Tarefa
Construir um pipeline completo para o repositório `technova-api` com: criação do repositório **Amazon ECR** e um script `ecr-push.sh` que autentica (`aws ecr get-login-password`) e publica a imagem no ECR com estratégia de tagging (SHA, latest e semver via git tags), operando no Learner Lab (`us-east-1`, credenciais temporárias, sem IAM); workflow de **AI Review** que dispara em Pull Requests, analisa o diff e posta um comentário categorizado por severidade; **quality gate** que bloqueia o PR em achados CRITICAL; e o documento `ia-cicd-analise.md` com a análise crítica sobre o uso de IA no review. Comprovar com screenshots (repositório no console do ECR com as tags, comentário do AI review, execução do push concluída e gate bloqueando).

---

## O que foi produzido

| Requisito | Entrega | Onde |
|-----------|---------|------|
| Build e push no ECR (40%) | `ecr-push.sh`: valida a sessão do Lab, cria o repositório `technova-api` de forma idempotente (scan on push + lifecycle policy), faz login no ECR, builda o Dockerfile multi-stage e publica `sha-XXXXXXX`, `latest` e semver (`1.2.3`, `1.2`, `1`) | `technova-api/ecr-push.sh` |
| Pull e rollback por tag | `ecr-rollback.sh <tag>`: pull do ECR, troca do container e health check | `technova-api/ecr-rollback.sh` |
| CI (Parte 7, opcional) | lint → test → build + smoke test → push no ECR com `aws-actions/configure-aws-credentials` + `amazon-ecr-login`, só em push para main/tags e com sessão do Lab válida | `.github/workflows/ci-aula09.yml` |
| AI Review (30%) | Dispara em `pull_request` (opened/synchronize/reopened), analisa as linhas adicionadas do diff com 20 regras e posta/atualiza um comentário em tabela por severidade | `.github/workflows/ai-review-aula09.yml`, `.github/scripts/ai-review.js` |
| Quality gate (10%) | CRITICAL → `exit 1` (check vermelho, PR bloqueado); WARNING/INFO só comentam | `ai-review-aula09.yml` |
| Documentação (20%) | Por que ECR e restrições do Lab, tagging, padrões, prompt/lógica, confiança vs review humano, limitações | `ia-cicd-analise.md` |
| Bônus | Lifecycle policy, scan on push, comentário atualizado sem duplicar, security scan dedicado (npm audit + Trivy), badges, 20 padrões, imagem com 0 CRITICAL/HIGH no Trivy | ver `README.md` |

## Dificuldades e decisões

- **Credenciais temporárias do Lab:** expiram a cada sessão e o Lab não permite IAM nem OIDC. Por isso o fluxo principal é o script local, e o CI pula o push com aviso (sem quebrar o pipeline) quando os secrets estão ausentes ou vencidos.
- **Workflows na raiz:** o GitHub só executa workflows de `.github/workflows/` na raiz do repositório. Os arquivos que rodam ficam lá, com o sufixo `-aula09`, para não conflitar com os das outras aulas. `aula-09/.github/` guarda uma cópia de referência com os nomes do enunciado (`ci.yml`, `ai-review.yml`).
- **Amazon Bedrock:** a camada de LLM foi implementada no `ai-review.js` (Converse API via AWS CLI, com as credenciais da sessão), mas no Learner Lab nenhum modelo pode ser chamado: os liberados (`claude-3-haiku` do laboratório e outros) estão descontinuados e os atuais dão `AccessDenied`. O review funciona pelas regras, que são as únicas que acionam o gate, e o LLM entra como camada consultiva com fallback automático. O teste com o Bedrock real e com uma resposta simulada está em `ia-cicd-analise.md`.

---

*Obs: Este é um documento para registro das atividades praticadas em sala de aula junto da turma de Análise e Desenvolvimento de Sistemas, sejam dinâmicas, trabalhos, seminários ou atividades práticas.*
