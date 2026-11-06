# Rollback — Blue/Green da TechNova API (Aula 11)

O rollback do Blue/Green não reimplanta nada: o ambiente anterior **continua rodando** atrás do
seu Target Group. Voltar é só apontar o listener HTTP:80 do ALB de novo para ele — uma chamada
à API do ALB que vale para conexões novas em poucos segundos.

O workflow `deploy-blue-green.yml` já faz isso sozinho quando a validação pós-switch falha.
Este documento cobre o rollback **manual** (problema percebido depois que o workflow terminou).

---

## 1. Comandos de rollback manual

Pré-requisito: credenciais do Learner Lab em `~/.aws/credentials` (AWS Details → AWS CLI).

### Opção 1 — script (recomendado)

```bash
cd unifaat-devops-portfolio

# Mostra quem está ativo (*), a saúde de cada Target Group e os IPs
./aula-11/scripts/bluegreen.sh status

# Volta o tráfego para a outra cor e valida pelo DNS do ALB
./aula-11/scripts/bluegreen.sh rollback
./aula-11/scripts/bluegreen.sh validate blue    # ou green — a cor que ficou ativa
```

### Opção 2 — AWS CLI direto

```bash
export AWS_DEFAULT_REGION=us-east-1

# Com o state do Terraform à mão
cd aula-11/terraform
LISTENER_ARN=$(terraform output -raw listener_arn)
BLUE_TG_ARN=$(terraform output -raw blue_tg_arn)
GREEN_TG_ARN=$(terraform output -raw green_tg_arn)

# Sem o state: pelos nomes que o Terraform criou
ALB_ARN=$(aws elbv2 describe-load-balancers --names 6325226-a11-alb \
  --query 'LoadBalancers[0].LoadBalancerArn' --output text)
LISTENER_ARN=$(aws elbv2 describe-listeners --load-balancer-arn "$ALB_ARN" \
  --query 'Listeners[?Port==`80`].ListenerArn | [0]' --output text)
BLUE_TG_ARN=$(aws elbv2 describe-target-groups --names 6325226-a11-blue \
  --query 'TargetGroups[0].TargetGroupArn' --output text)

# Para onde o tráfego vai agora?
aws elbv2 describe-listeners --listener-arns "$LISTENER_ARN" \
  --query 'Listeners[0].DefaultActions[0].TargetGroupArn' --output text

# O ambiente de destino está saudável?
aws elbv2 describe-target-health --target-group-arn "$BLUE_TG_ARN" \
  --query 'TargetHealthDescriptions[].TargetHealth.State'

# ROLLBACK: 100% do tráfego de volta para Blue (troque por $GREEN_TG_ARN se Green era o anterior)
aws elbv2 modify-listener --listener-arn "$LISTENER_ARN" \
  --default-actions Type=forward,TargetGroupArn="$BLUE_TG_ARN"

# Confirmação pelo ALB: o /health informa a cor que está respondendo
curl -s "http://$(terraform output -raw alb_dns_name)/health"
```

> **Não use `terraform apply` para fazer rollback.** O listener tem `ignore_changes = [default_action]`:
> o Terraform cria o listener apontando para Blue e, depois disso, quem decide a cor ativa são o
> workflow e este procedimento.

---

## 2. Critérios que indicam rollback

Qualquer um destes, **depois** de um switch:

| Sinal | Limite | Como ver |
|-------|--------|----------|
| Respostas 5xx na API de pedidos | qualquer erro na validação; em produção, > 1% em 5 min | `bluegreen.sh validate <cor>`, métrica `HTTPCode_Target_5XX_Count` do ALB |
| Target Group ativo com target `unhealthy` | 1 target unhealthy | `bluegreen.sh status` |
| `/version` não reporta o commit implantado | qualquer divergência | `curl http://<alb>/version` |
| Latência p95 acima do normal | > 2× a linha de base do ambiente anterior | métrica `TargetResponseTime` do ALB |
| Erro funcional relatado (pedido não criado, dado errado) | 1 relato confirmado | suporte / logs `docker logs technova-api` |

Na dúvida, **faça o rollback primeiro e investigue depois**: o ambiente novo continua rodando,
sem tráfego, disponível para a análise.

## 3. Tempo máximo antes de decidir

- **Validação automática:** o workflow decide em cerca de 1 min depois do switch (cor nova no `/health`,
  commit no `/version` e 20 requisições em `/api/orders`).
- **Rollback manual:** no máximo **5 minutos** entre o primeiro sinal da tabela acima e a decisão.
  O rollback leva segundos e não tem efeito colateral, então esperar mais só aumenta o impacto
  para o cliente.
- **Janela de segurança:** o ambiente anterior **não** é desligado nem sobrescrito até o próximo
  deploy. Enquanto ele existir, o rollback continua sendo instantâneo.

## 4. Checklist pós-rollback

- [ ] `bluegreen.sh status` mostra a cor anterior ativa (`*`) e `healthy`
- [ ] `curl http://<alb>/health` responde 200 com a cor anterior; `/api/orders` responde 200
- [ ] Logs do ambiente que falhou guardados antes do próximo deploy (ele será sobrescrito):
      `ssh -i ~/.ssh/technova-aula10-deploy.pem ec2-user@<ip> 'docker logs technova-api' > falha.log`
- [ ] Link da execução do workflow e horário do rollback anotados
- [ ] Time notificado (o workflow comenta no commit e, com o secret `DISCORD_WEBHOOK`, avisa no Discord)
- [ ] Issue aberta com o commit revertido, sintoma e evidências
- [ ] Postmortem sem culpados em até 48 h: linha do tempo, causa raiz, por que os testes do CI não
      pegaram, ação para evitar a repetição
- [ ] Correção entra por um novo PR → novo deploy Blue/Green (não "consertar" o ambiente na mão)
