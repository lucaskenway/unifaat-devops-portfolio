# Runbook: Deploy falhou em produção

| Campo | Valor |
|---|---|
| Serviço | TechNova API (`technova-api`, EC2 `6325226-technova-aula12-api`) |
| Dono | Plantão DevOps (RA 6325226) |
| Última revisão | 2026-11-06 |

## Trigger

Qualquer um destes sinais, nos 15 minutos depois de um deploy:

- O workflow **CD with Automated Rollback — Aula 12** ficou vermelho, e o step `🚨 Rollback automático` rodou ou foi pulado (`steps.previous.outputs.tag` vazio).
- Chegou um e-mail SNS `[P1] TechNova: rollback automático`.
- Um destes alarmes entrou em `ALARM`: `TechNova-HighError5xx`, `TechNova-HighLatency`, `TechNova-ResponseTime-Anomaly` ou `TechNova-Incident-LatencyAndErrors`.
- A Lambda `TechNovaAIOpsAnalyzer` respondeu com `rollback_necessario: true`.

## Severidade: P1 (impacto em produção)

| Situação | Severidade | Tempo de resposta |
|---|---|---|
| `/health` fora do ar ou 5xx > 10/min | **P1** | agir em até 5 min |
| Latência > 1 s sem erros | P2 | até 30 min |
| Só uma feature com problema, e ela está atrás de flag | P2 | desligar a flag já |

## Diagnóstico rápido (< 2 minutos)

```bash
cd aula-12/terraform && HOST=$(terraform output -raw api_public_ip)

# 1. A API responde? Qual versão está no ar?
curl -s -w '\nHTTP %{http_code}\n' http://$HOST:3000/health
curl -s http://$HOST:3000/version | jq '{imageTag, commit, deployedAt, flags}'

# 2. Container e versão anterior (label gravado pelo deploy)
ssh -i ~/.ssh/technova-aula10-deploy.pem ec2-user@$HOST \
  'docker ps --filter name=technova-api; docker inspect -f "{{index .Config.Labels \"previous.version\"}}" technova-api'

# 3. Erros recentes (o container loga no CloudWatch Logs)
aws logs tail /technova/api --since 15m --filter-pattern '?ERROR ?FATAL ?TypeError'

# 4. Estado dos alarmes
aws cloudwatch describe-alarms --alarm-name-prefix TechNova- \
  --query 'MetricAlarms[].[AlarmName,StateValue]' --output table
```

Decisão:

- O erro começou com o deploy e atinge a API inteira: faça o **rollback** (abaixo).
- O erro fica numa feature que tem flag (por exemplo, o frete): **desligue a flag**. Isso é mais rápido e não descarta o resto do deploy.
- Há timeouts de banco ou de serviço externo: não faça rollback, porque ele não resolve. Escale para quem cuida da infraestrutura.

## Ação 1 — Rollback manual (se o automático não rodou)

```bash
# Envia o script e roda na EC2. Sem 3º argumento ele usa o label previous.version.
scp -i ~/.ssh/technova-aula10-deploy.pem aula-12/scripts/rollback.sh ec2-user@$HOST:/tmp/
ssh -i ~/.ssh/technova-aula10-deploy.pem ec2-user@$HOST 'bash /tmp/rollback.sh technova-api'

# Para escolher outra versão, liste as tags no ECR e passe a tag:
aws ecr describe-images --repository-name technova-api \
  --query 'sort_by(imageDetails,&imagePushedAt)[-5:].[imageTags[0],imagePushedAt]' --output table
ssh ... 'bash /tmp/rollback.sh technova-api "" a12-sha-XXXXXXX'
```

O script faz login no ECR antes do `docker pull`, porque o token do Lab expira. Depois sobe a imagem anterior e espera o `/health` responder 200.

## Ação 2 — Mitigar por feature flag (sem rollback e sem redeploy)

```bash
scp -i ~/.ssh/technova-aula10-deploy.pem aula-12/scripts/toggle-flag.sh ec2-user@$HOST:/tmp/
ssh -i ~/.ssh/technova-aula10-deploy.pem ec2-user@$HOST 'bash /tmp/toggle-flag.sh FF_NEW_SHIPPING_CALC false'
```

O script recria o container com a **mesma imagem**. O frete volta para o v1 (R$ 10 fixo) em cerca de 3 segundos. Confira com `curl -s http://$HOST:3000/version | jq .flags`.

## Ação 3 — Banco de dados

As migrações seguem o padrão expand-contract, então a versão anterior da API funciona com o schema novo. **Não reverta a migração junto com o rollback da API.** Use `node migrations/cli.js down <versão>` só se a própria migração for a causa. Como o `down` remove colunas, primeiro confirme que nenhuma versão no ar ainda lê essas colunas.

## Verificação

- [ ] `curl http://$HOST:3000/health` responde HTTP 200 três vezes seguidas, com 10 s entre elas.
- [ ] `/version` mostra a `imageTag` esperada.
- [ ] `TechNova-HighError5xx` e `TechNova-HighLatency` voltam para `OK`. Isso leva de 2 a 3 minutos.
- [ ] `aws logs tail /technova/api --since 5m` não mostra erros novos.
- [ ] Teste rápido: `POST /api/orders` responde 201.

## Escalação

| Tempo sem resolver | Quem acionar |
|---|---|
| 15 min | Tech lead do time da API |
| 30 min | CTO e comunicação aos clientes (status page) |
| Problema de AWS (EC2/ECR fora) | Suporte AWS / professor (Learner Lab) |

## Post-mortem (até 48 h depois)

Comece pelo rascunho que a Lambda AIOps grava nos logs (`aws logs tail /aws/lambda/TechNovaAIOpsAnalyzer`). Complete com a linha do tempo, a causa raiz confirmada por um humano, o que funcionou (o rollback automático disparou?) e uma ação preventiva com dono e prazo.
