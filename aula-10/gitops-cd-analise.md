# Aula 10 — Análise: Terraform GitOps e Pipeline CD

**Aluno:** Weslley Lucas Souza Alves — **RA:** 6325226
**Contexto:** "A partir de hoje, nenhum humano executa Terraform diretamente e nenhum deploy é manual." — CTO da TechNova

---

## 1. Fluxo GitOps do Terraform

```
branch feat/*  ──►  Pull Request  ──►  terraform-plan.yml
                                        fmt -check → init → validate → plan
                                        └─► comentário no PR (atualizado a cada push)
                                        └─► gate: destroy só com a label allow-destroy
                    revisão humana do plan
                         │
                       merge
                         ▼
                  push na main  ──►  terraform-apply.yml
                                        init → apply -auto-approve → outputs
                                        └─► workflow_run dispara o cd.yml (redeploy na EC2)
```

### Por que plan no PR e apply no merge

- **O plan é o que se revisa.** Diff de `.tf` mostra a intenção; o plan mostra o efeito real contra o state (o que será criado, alterado, **destruído** ou **recriado**). Uma mudança de uma linha em `user_data` ou em `ami` aparece no plan como *replace* da EC2, coisa que o diff do código não deixa óbvio.
- **O merge é a aprovação.** Com branch protection (PR obrigatório + check "Terraform Plan" verde), o único jeito de mudar a infra é passar por revisão. O `-auto-approve` no apply é seguro porque a confirmação humana aconteceu no PR — e no CI não existe terminal para responder ao prompt.
- **A `main` é a fonte da verdade.** O que está na main é o que está na AWS; o histórico do Git vira o histórico da infraestrutura (quem mudou, quando, por quê, com link para o plan revisado).
- **State remoto + lock.** O backend S3 + DynamoDB (padrão da Aula 05: bucket `technova-tfstate-<ACCOUNT_ID>`, key `aula-10/terraform.tfstate`, criado uma vez por `scripts/bootstrap-backend.sh`) garante que o plan do PR e o apply do merge enxergam o mesmo state, e o lock impede dois applies simultâneos. O `concurrency: terraform-aula10` do workflow reforça isso enfileirando applies em vez de cancelá-los.

### Proteções implementadas

| Proteção | Como |
|----------|------|
| Plan válido obrigatório | O step de plan tem `continue-on-error` só para o comentário ser postado; depois o job falha se o plan falhou |
| Formatação | `terraform fmt -check -recursive` falha o check |
| Destroy exige aprovação extra | `terraform show -json tfplan \| jq` conta ações `delete` (inclui *replace*); se > 0, o check falha até alguém adicionar a label `allow-destroy` ao PR |
| Comentário sem duplicação | Marcador HTML `<!-- terraform-plan-aula10 -->`: o workflow procura o comentário anterior e o **atualiza** |
| Comentário grande | Output truncado em 60 000 caracteres (limite de ~65k do GitHub), com link para o log completo |
| Destroy manual | `terraform-destroy.yml` só roda por `workflow_dispatch`, digitando `destroy`, e passa pelo environment `production-destroy` (required reviewers) |
| Plan estável | `lifecycle { ignore_changes = [ami] }` na EC2: sem isso, toda nova AMI do Amazon Linux faria o plan propor recriar a instância |

---

## 2. Autenticação no AWS Academy Learner Lab

### Como está implementado

Os três valores da sessão do Lab (**AWS Details → AWS CLI: Show**) são GitHub Secrets do repositório:

| Secret | Uso |
|--------|-----|
| `AWS_ACCESS_KEY_ID` | `ASIA...` — chave temporária |
| `AWS_SECRET_ACCESS_KEY` | segredo da chave |
| `AWS_SESSION_TOKEN` | token de sessão — sem ele, credenciais `ASIA` são rejeitadas |

Todos os workflows usam `aws-actions/configure-aws-credentials@v4` com as três entradas e `aws-region: us-east-1`. Na EC2, o login no ECR usa as mesmas credenciais (passadas pelo `envs` do `appleboy/ssh-action`) e, como reserva, o **LabInstanceProfile** anexado à instância pelo Terraform.

**Limitação prática:** as credenciais expiram quando a sessão do Lab termina (~4 h). Depois disso todos os workflows falham com `ExpiredToken` até os três secrets serem atualizados. Por isso a sequência de evidências precisa ser feita dentro de uma sessão.

### Por que OIDC + role IAM seria o ideal em produção

```yaml
# Produção (NÃO executável no Lab)
permissions:
  id-token: write
steps:
  - uses: aws-actions/configure-aws-credentials@v4
    with:
      role-to-assume: arn:aws:iam::<ACCOUNT_ID>:role/github-actions-terraform
      aws-region: us-east-1
```

- **Nenhum segredo de longa duração.** O GitHub emite um token OIDC por execução; a AWS troca por credenciais que valem ~1 h. Não há chave para vazar, rotacionar ou esquecer em um secret.
- **Escopo controlado pela trust policy.** A role pode aceitar só `repo:lucaskenway/unifaat-devops-portfolio:ref:refs/heads/main` — um fork ou outra branch não consegue assumir a role de apply.
- **Menor privilégio por workflow.** Uma role só-leitura para o plan dos PRs e outra com escrita para o apply na main. Com credenciais de sessão, plan e apply têm exatamente as mesmas permissões (as do `voclabs`).
- **Auditoria.** O CloudTrail registra o `AssumeRoleWithWebIdentity` com repositório, branch e run.

### Por que o Lab não permite

O role assumido pelo aluno (`voclabs`) não tem `iam:CreateOpenIDConnectProvider`, `iam:CreateRole` nem `iam:AttachRolePolicy`. As únicas roles disponíveis são as gerenciadas pela Academy (`LabRole` / `LabInstanceProfile`), cuja trust policy não pode ser editada para confiar no `token.actions.githubusercontent.com`. Por isso não há `oidc.tf` nesta entrega.

---

## 3. Estratégia Recreate

Implementação no job `deploy` do `cd.yml`, via SSH na EC2:

```
login ECR → docker stop → docker rm → docker pull <sha-XXXXXXX> → docker run → health check
```

| Prós | Contras |
|------|---------|
| A mais simples possível: um container, sem load balancer | **Downtime** entre o `stop` e o novo container responder (pull + boot) |
| Nunca existem duas versões rodando — sem problema de compatibilidade de schema/sessão entre versões | Se a nova versão não sobe, a app fica **fora** até o rollback |
| Usa só uma máquina (custo mínimo — cabe no Lab) | Rollback também tem downtime |
| Fácil de entender e depurar | Não serve para tráfego que não tolera interrupção |

**Quando usar:** ambientes de dev/staging, ferramentas internas, janelas de manutenção aceitas, ou quando a mudança é incompatível com a versão antiga rodando em paralelo (ex.: migração de banco destrutiva). Para produção com usuários reais, Blue-Green (Aula 11) ou Canary (Aula 12).

**Detalhes de implementação:**
- O deploy usa a tag **imutável** `sha-XXXXXXX` (não `latest`), então o que roda é exatamente o que o pipeline acabou de testar e o rollback é só trocar a tag.
- `docker stop ... || true` e `docker rm ... || true` tornam o primeiro deploy (sem container) idempotente.
- O script espera o Docker ficar pronto, porque logo após um apply o `user_data` ainda pode estar instalando.
- **Melhoria possível sem mudar de estratégia:** fazer o `docker pull` **antes** do `stop` reduziria o downtime ao tempo de boot do container. Mantive a ordem do enunciado (stop → rm → pull → run).

### Health check

Após o deploy, o runner chama `http://<EC2>:3000/health` até 20 vezes, a cada 5 s. Se não receber HTTP 200, o job falha e o pipeline fica vermelho. Em seguida o pipeline confere que `/version` reporta o commit (`GITHUB_SHA`) recém-implantado, o que garante que o health check não está respondendo um container antigo.

---

## 4. Continuous Delivery vs Continuous Deployment

| | Continuous Delivery | Continuous Deployment |
|---|---|---|
| Até onde é automático | Até o artefato **pronto para produção** (testado, publicado) | Até **produção** |
| Ida para produção | Decisão humana (botão / aprovação) | Todo commit na main que passa no pipeline |
| No GitHub Actions | `environment: production` com *required reviewers* | `environment: production` sem regras de proteção |
| Exige | Pipeline confiável | Pipeline confiável **+** testes fortes, health check, rollback rápido, monitoramento |

Este `cd.yml` é **Continuous Deployment**: push na main → produção sem intervenção. Para virar Continuous Delivery basta configurar *required reviewers* no environment `production` (Settings → Environments); o job `deploy` passaria a esperar aprovação, sem mudar uma linha do YAML. O destroy da infra, por outro lado, é deliberadamente **Delivery** (environment `production-destroy` com aprovação).

---

## 5. Rollback

Procedimento completo em [`docs/runbook-rollback.md`](docs/runbook-rollback.md). Resumo:

1. Escolher a tag `sha-XXXXXXX` estável (console do ECR ou `aws ecr describe-images`).
2. SSH na EC2.
3. **Login no ECR antes do pull** (`aws ecr get-login-password | docker login ...`) — sem isso o `docker pull` falha com `no basic auth credentials`.
4. `stop` → `rm` → `run` com a tag antiga.
5. `curl /health` e `curl /version`.
6. Corrigir na main com `git revert` — senão o próximo merge reimplanta a versão problemática.

---

## 6. Limitações identificadas e melhorias

| Limitação | Impacto | O que melhoraria |
|-----------|---------|------------------|
| Credenciais de sessão do Lab expiram (~4 h) | Todos os workflows quebram até atualizar 3 secrets | OIDC + role IAM (produção) |
| SSH aberto para `0.0.0.0/0` (runners sem IP fixo) | Superfície de ataque; mitigado por só aceitar chave | AWS SSM Run Command / Session Manager no lugar de SSH, ou self-hosted runner na VPC |
| IP público muda quando o Lab reinicia a EC2 | `EC2_HOST` fixo fica errado | Já mitigado: o pipeline descobre o IP pela tag `Name`; em produção, Elastic IP ou DNS |
| Recreate tem downtime | Indisponível durante o deploy | Pull antes do stop; Blue-Green / Canary nas próximas aulas |
| Rollback manual | Depende de alguém com acesso SSH | Workflow `workflow_dispatch` de rollback recebendo a tag; rollback automático quando o health check falha |
| Plan e apply com as mesmas permissões | Um PR malicioso poderia rodar código no plan com credenciais de escrita | Roles separadas (read-only no plan) via OIDC |
| Plan salvo não é reaproveitado no apply | O apply recalcula; se a AWS mudou entre o PR e o merge, aplica algo diferente do revisado | Publicar o `tfplan` como artifact e aplicar exatamente ele, ou rodar plan de novo e comparar |
| Sem cost estimation | Mudança cara passa despercebida | Infracost no workflow de plan |
| Sem notificação externa | Time só vê pelo GitHub | Webhook Slack/Discord (hoje: comentário no commit + step summary) |

### Bônus implementados

- [x] Plan que detecta destroy e exige aprovação extra (label `allow-destroy`)
- [x] Comentário no PR atualizado (não duplicado)
- [x] Deploy com `GITHUB_SHA` (rastreabilidade via `/version`, conferida no pipeline)
- [x] Notificação de deploy (comentário no commit)
- [x] `terraform fmt -check` no workflow de plan
- [ ] Cost estimation (Infracost)
- [x] Workflow separado para destroy com aprovação manual
- [x] GitHub Environment (`production`; protection rules configuráveis sem mudar o YAML)
