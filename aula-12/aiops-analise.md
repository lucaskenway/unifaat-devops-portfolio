# Análise crítica: AIOps na TechNova

**Aluno:** Weslley Lucas Souza Alves — RA 6325226
**Data:** 06/11/2026
**Ambiente:** AWS Academy Learner Lab, conta `844303000847`, região `us-east-1`. O Lab **não tem acesso ao Bedrock**.

## 1. O que foi montado

```
API (EC2/Docker) ──PutMetricData──▶ CloudWatch  TechNova/API  {ResponseTime, Error5xx, Error4xx, OrdersCreated, OrdersFailed}
     │ awslogs                           │
     ▼                                   ├─ TechNova-HighLatency          (fixo: média > 1000 ms, 3 de 3 min)
CloudWatch Logs /technova/api            ├─ TechNova-HighError5xx         (fixo: > 10 por min, 2 de 2 min)
     ▲                                   ├─ TechNova-ResponseTime-Anomaly (ANOMALY_DETECTION_BAND(m1, 2), 2 de 3 min)
     │ FilterLogEvents                   ├─ TechNova-Error5xx-Anomaly     (banda de anomalia nos 5xx)
     │                                   └─ TechNova-Incident-LatencyAndErrors (composto: latência E erros)
     │                                              │ state change → ALARM
     │                                              ▼
     └──────────────── Lambda TechNovaAIOpsAnalyzer (LabRole) ◀── EventBridge "TechNova-Anomaly-Trigger"
                        │ GetMetricData (15 min) + logs de erro
                        │ Bedrock? → não disponível no Lab → análise por regras (analysis.js)
                        ▼
                  SNS technova-alerts  +  rascunho de post-mortem no log
```

## 2. O que aconteceu no teste de ponta a ponta

O `scripts/force-alarm.sh` publicou `ResponseTime = 2200 ms` e `Error5xx = 8` a cada 30 s, durante 5 min. Evidência: `evidencias/…/006_*`, mais o gráfico `screenshots/cloudwatch-metrics-anomaly-band.png`.

| Hora (UTC) | Evento |
|---|---|
| 22:49:00 | `TechNova-HighError5xx` → ALARM (16 erros/min > 10, 2 períodos) |
| 22:49:00 | EventBridge invoca a Lambda pela primeira vez |
| 22:50:14 | `TechNova-HighLatency` → ALARM (3 períodos > 1000 ms) |
| 22:50:15 | `TechNova-Incident-LatencyAndErrors` (composto) → ALARM, Lambda invocada de novo |

Tempo entre a métrica ruim e a análise na caixa do SNS: **cerca de 2 a 3 min**. Quase todo esse tempo é a janela de avaliação dos alarmes. A Lambda leva menos de 1 s.

Os dois alarmes de **anomaly band continuaram em `OK`**. O console mostra o aviso ⚠ na banda porque o detector foi criado minutos antes e não tem histórico para aprender o padrão (a AWS fala em até duas semanas). Para o lab, isso é o comportamento esperado. Em produção, os primeiros dias são justamente quando o alarme fixo precisa cobrir sozinho.

## 3. Sem Bedrock: regras + Kiro AI

A Lambda tenta o `InvokeModel` (Claude 3 Haiku) quando `USE_BEDROCK=true`. No Lab da turma ficou `false`, então ela usa `analysis.js`. São regras de SRE sobre os logs e a tendência das métricas, nesta ordem:

1. Um `TypeError` repetido depois de um deploy vira **P1 com rollback**.
2. Heap ou memória crescendo vira **P2, restart**.
3. Timeout ou pool esgotado vira **P1 sem rollback**, porque é infraestrutura.
4. Um 5xx alto sem stack trace vira P1 se a latência também estiver alta, ou P2 se não.
5. Latência alta sozinha vira P2.

O `local-simulator.js` roda os 3 cenários do lab (latência por pool de banco, bug no deploy, memory leak) com as mesmas regras e acerta **3 de 3** na severidade e na decisão de rollback. `node local-simulator.js 2 --prompt` imprime o mesmo prompt que iria para o Bedrock, para colar no Kiro AI e comparar com a análise por regras. A saída do simulador está em `screenshots/aiops-analysis.png`, e a da Lambda real, em `screenshots/aiops-lambda-invoke.png` e `screenshots/cloudwatch-alarm.png`.

**Erro que o teste real mostrou:** na primeira versão, o alarme `TechNova-HighError5xx` chegou à Lambda e foi classificado como "latência 2200 ms, P2". O motivo é que não havia regra para 5xx sem stack trace, e a regra de latência pegou o caso. Corrigi a regra (item 4 acima) e reapliquei a Lambda. É o tipo de falha que só aparece com evento de verdade, e não nos cenários prontos.

## 4. Quando confiar na IA (ou nas regras) e quando não

| Confiar | Não confiar |
|---|---|
| **Correlacionar sinais rápido.** Juntar métricas, logs e o último deploy em segundos, às 3 da manhã. | **Decidir sozinha um rollback de banco ou uma ação destrutiva.** O `down` de migração apaga colunas, e quem decide é um humano. |
| **Triar e escrever.** Severidade sugerida, resumo e rascunho de post-mortem poupam tempo de quem está de plantão. | **Explicar a causa raiz com "confiança alta" sem evidência citada.** Um LLM pode inventar um nome de tabela ou uma query que não existe nos logs. |
| **Padrões conhecidos e repetidos.** Um `TypeError` logo depois do deploy é um caso clássico de rollback. | **Incidentes novos, fora do que o prompt ou as regras conhecem.** A tendência é cair numa resposta genérica e plausível. |

Regra que adotei: **a IA recomenda e o pipeline age só com sinal objetivo.** O rollback automático deste trabalho é disparado pelo **health check** (janela 6×10 s), e não pela Lambda. A análise da IA vai para o humano, com o campo `confianca` e a lista de `evidencias` justamente para ser conferida.

## 5. Limitações e falsos positivos observados

- **Anomaly detection sem histórico:** sem dados, não há banda útil. No começo, ou o alarme não dispara, ou fica sensível demais a qualquer pico. Por isso existe o alarme fixo em paralelo.
- **Picos legítimos:** uma promoção ou um job em lote parecem "anomalia". O detector aprende a sazonalidade semanal só depois de algumas semanas. Até lá, a mitigação é `datapoints_to_alarm = 2 de 3` e o alarme composto, que exige latência E erros juntos.
- **Tráfego baixo:** no lab, poucos requests por minuto fazem um único request lento mover a média. `treat_missing_data = notBreaching` evita alarme por falta de dado, mas não por amostra pequena.
- **Uma só dimensão:** os alarmes olham `Environment=production` agregado. Um endpoint quebrado com pouco tráfego pode ficar escondido na média. As séries por `Endpoint` existem para o diagnóstico.
- **Duplicação de alertas:** um incidente gerou 3 invocações (um 5xx, uma latência, um composto). Em produção, eu deixaria só o composto mandar e-mail ou página, e os outros iriam só para o dashboard.
- **Custo e privacidade:** mandar logs para um LLM pode levar dados de clientes junto. Antes de ligar o Bedrock, eu aplicaria um filtro de PII aos logs (e-mail, CPF).

## 6. Conclusão

AIOps ajuda na **detecção e na triagem**: o alarme composto mais a análise automática encurtam o "o que está acontecendo?". A **ação** que tira a API do ar ou a traz de volta continua apoiada em sinais determinísticos (health check, flag, versão anterior no ECR), que dá para auditar e repetir. Quando o Bedrock estiver disponível, ele substitui o `analysis.js` como *primeira opinião*, e as regras ficam como fallback.
