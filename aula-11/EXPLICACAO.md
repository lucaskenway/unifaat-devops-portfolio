# EXPLICACAO — Aula 11: Blue/Green Deployment

**Aluno:** Weslley Lucas Souza Alves — RA 6325226
**Data:** 06/11/2026
**Ambiente:** AWS Academy Learner Lab, conta `844303000847`, `us-east-1`

## 1. Opção escolhida: A — Blue/Green

Escolhi Blue/Green por três motivos:

- **O rollback é imediato e não depende de build.** A versão anterior continua rodando atrás do outro Target Group. Voltar é uma chamada `modify-listener`, que no lab levou de 2,6 s a 3,4 s.
- **Para uma API de pedidos, tudo ou nada é aceitável.** As versões mudam pouco, e eu prefiro validar a versão nova inteira antes de ela receber tráfego. O Canary faria parte dos clientes passar pela versão nova durante o rollout.
- **A validação é determinística.** Antes do switch, o ALB confirma o health check do Target Group ocioso. Depois do switch, o workflow manda 20 requisições reais em `/api/orders`. Não preciso de métricas estatísticas por porcentagem de tráfego, que com o volume do lab seriam pouco confiáveis.

O custo é manter duas EC2 (`t3.micro`) sempre ligadas. No Lab isso é aceitável. Em produção, esse é o ponto principal contra a estratégia.

## 2. Arquitetura

```
                         Internet
                            │  HTTP :80
                            ▼
            ┌──────────────────────────────────┐
            │  ALB 6325226-a11-alb  (SG alb)   │  2 subnets públicas (us-east-1a/1b)
            │                                  │
            │  Listener :80  ──forward──▶ TG ATIVO        ← o switch troca só isto
            │  Listener :8080 ─forward──▶ blue + green    ← só para manter os 2 TGs com
            │  (8080 fechado no SG)                          health check ativo
            └──────────┬───────────────┬───────┘
                       │               │   health check GET /health/ready (readiness)
              TG 6325226-a11-blue   TG 6325226-a11-green
                       │               │
                       ▼               ▼  :3000 (SG ec2: só aceita o SG do ALB; SSH p/ deploy)
               EC2 ...-blue        EC2 ...-green       ← LabInstanceProfile (pull do ECR)
               docker technova-api docker technova-api
                       ▲               ▲
                       └──── docker pull ◀── Amazon ECR technova-api:bg-<sha>
```

## 3. Como funciona o deploy (push na `main`)

1. **Lint & Tests:** `npm ci`, ESLint e Jest. Os testes cobrem também o `SIMULATE_ERRORS` e o `/health/ready`.
2. **Build & Push:** login no ECR com as credenciais temporárias do Lab. O workflow garante que o repositório e a lifecycle policy existem, faz o build multi-stage e publica `technova-api:bg-<sha7>`.
3. **Estado atual:** `bluegreen.sh status` lê o listener :80 e descobre qual Target Group está ativo.
4. **Descobrir o ocioso:** o ambiente que vai receber a versão é a outra cor. As cores se alternam a cada deploy.
5. **Deploy no ocioso por SSH:** na EC2 ociosa, o workflow faz `aws ecr get-login-password | docker login`, depois `docker pull` da tag nova e `docker run` com `APP_COLOR`, `GITHUB_SHA` e `DEPLOY_TIME`. O ambiente ativo não é tocado.
6. **Health check do Target Group:** `bluegreen.sh wait-healthy` espera até o ALB marcar o alvo como `healthy` no `/health/ready`. Esse endpoint testa a camada de dados e a memória, não só se o processo responde.
7. **Traffic switch:** `aws elbv2 modify-listener` passa 100% do tráfego da :80 para a cor nova.
8. **Validação pelo DNS do ALB:** o workflow exige 10 respostas seguidas da cor nova (por causa da propagação, ver §4). Depois confere se o `/version` mostra o commit do deploy e se as 20 requisições em `/api/orders` respondem 200.

## 4. Como funciona o rollback

Se qualquer item da validação falhar (§3, passo 8):

1. O step **Rollback automático** roda `bluegreen.sh switch <cor anterior>`. O listener volta para o Target Group antigo, que continuou rodando a versão anterior sem nenhuma alteração.
2. O workflow roda `validate` de novo na cor antiga, com as mesmas 20 requisições.
3. O step **Notificar rollback** publica um comentário no commit (e manda para o Discord, se o webhook existir). O workflow termina **vermelho** para ninguém achar que o deploy entrou.
4. O ambiente com falha fica de pé, mas sem tráfego. Isso permite investigar o container com `docker logs` antes do próximo deploy, que vai sobrescrevê-lo.

O teste foi feito em `workflow_dispatch` com `simulate_failure=true`, no run [42310187138](https://github.com/lucaskenway/unifaat-devops-portfolio/actions/runs/42310187138):

```
[23:12:53] target group green: healthy                  ← /health continua 200: o TG aceita
[23:12:59] 🔀 tráfego blue → green em 3132 ms
[23:13:14] ❌ requisição 1/20 em /api/orders: HTTP 500   ← SIMULATE_ERRORS=true
[23:13:16] ERRO: 20/20 requisições falharam (taxa de erro 100%)
[23:13:23] 🔀 tráfego green → blue em 2944 ms             ← rollback
[23:13:35] ainda há resposta da cor antiga (propagação), recomeçando a contagem
[23:13:40] ✅ 20/20 requisições OK em /api/orders         ← blue de volta
```

**Dois bugs que só apareceram no lab real**, ambos corrigidos:

- **Target Group ocioso `unused`** (PR #13). O ALB só faz health check de um TG ligado a algum listener. O green ficava `Target.NotInUse`, e o primeiro deploy esperou 300 s até falhar. A correção foi um listener :8080 com forward para os dois TGs. A porta 8080 não está aberta no SG, então não fica exposta.
- **Propagação do switch** (PR #15). No primeiro teste de rollback, o listener já apontava para o green, mas 4 de 20 requisições ainda chegaram ao blue: os nós do ALB levam alguns segundos para aplicar o `modify-listener`. Agora a validação exige `STABLE_CHECKS=10` respostas seguidas da cor certa.

## 5. Quanto tempo leva (medido nos runs 42309886648 e 42310187138)

| Etapa | Tempo |
|---|---|
| Lint & Tests | 16 s |
| Build & Push (ECR, com cache de camadas) | 18–23 s |
| Estado atual + descobrir o ocioso | 17–18 s |
| Deploy no ocioso (login ECR + pull + run) | 3–4 s |
| Health check do TG ficar healthy | 1–2 s (até ~30 s na 1ª subida de uma EC2) |
| **Traffic switch** (chamada à API) | **2,6–3,1 s** |
| Validação pós-switch (com propagação) | 14–17 s |
| **Pipeline completo de um deploy OK** | **~1 min 30 s** (48 s no job Blue/Green) |
| **Rollback** (switch de volta) | **2,9 s** |
| Rollback completo (switch + propagação + validação) | ~24 s (de 23:13:16 a 23:13:40) |
| Da falha detectada ao fim do workflow | ~37 s |

Os clientes ficaram expostos à versão quebrada por **cerca de 25 s** (23:12:59 → 23:13:23): o tempo da validação mais o do switch de volta. Em comparação, o Recreate da Aula 10 deixava a API fora do ar durante o pull e o start, e um rollback exigia um novo deploy completo, de 1 a 2 minutos.

## 6. O que faria diferente em produção real

1. **OIDC + role IAM no GitHub Actions**, no lugar das 3 credenciais temporárias do Lab salvas como secrets. Elas expiram a cada sessão de 4 h, e eu tenho que atualizá-las à mão.
2. **SSM Run Command no lugar de SSH.** Hoje a porta 22 está aberta para `0.0.0.0/0`, porque os runners do GitHub não têm IP fixo. Com o SSM, a porta 22 fecha e o acesso passa a ser controlado e auditado por IAM.
3. **ECS/Fargate com CodeDeploy (blue/green nativo)** ou um Auto Scaling Group por cor, no lugar de duas EC2 fixas. O ambiente ocioso nasceria só durante o deploy, o que corta o custo dobrado.
4. **Validação por métricas, não só por 20 requisições.** Eu observaria o `HTTPCode_Target_5XX_Count` e a latência p95 do Target Group no CloudWatch durante alguns minutos, com rollback por alarme. A Aula 12 faz isso com a janela de observação e os alarmes.
5. **HTTPS no listener** (ACM + :443) e redirect de 80 para 443.
6. **Migrações de banco compatíveis com as duas versões** (expand-contract, Aula 12). Num Blue/Green com banco compartilhado, essa é a condição para o rollback de 3 s continuar valendo.

## Evidências

- `screenshots/01-alb-502-antes-do-deploy.png`: ALB recém-criado, sem alvo saudável.
- `screenshots/02-deploy-blue-green-sucesso.png`: run de deploy verde.
- `screenshots/03-alb-respondendo-version.png`: `/version` pelo DNS do ALB (`color: blue`).
- `screenshots/04-rollback-automatico-run.png`: run do `simulate_failure`, com o rollback executado.
- `evidencias/2026-11-06_*_aula-11-blue-green-deploy-e-rollback/003_*`: log real dos dois runs.
