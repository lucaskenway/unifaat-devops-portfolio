# Evidências — aula-12 rollback e aiops

- **Projeto:** `portfolio-aula12`
- **Início da sessão:** 2026-11-06T19:41:52-03:00
- **Fim da sessão:** 2026-11-06T20:18:32-03:00
- **Ambiente:** WSL (Ubuntu) Ubuntu 26.04 LTS · usuário `lucaskenway` · host `DESKTOP-AMJ5UEC`
- **Comandos registrados:** 9 (7 com retorno 0, 2 com falha) · **capturas de tela:** 0

> Gerado pela ferramenta `evidencia`. Os TXT contêm a saída capturada diretamente dos processos, sem edição; a única alteração possível é a troca de dados sensíveis por `[REDIGIDO:tipo]`, sempre informada abaixo. Imagens **renderizadas** são desenhadas a partir do TXT e **não são capturas de tela**; capturas **autênticas** são cópias dos pixels da tela.

## Índice

| # | Horário | Descrição | Comando | Retorno | Arquivos |
|---|---------|-----------|---------|---------|----------|
| 001 | 19:42:03 | Migracoes expand-contract: status, up, down 001, down 000, up de novo (Postgres na EC2 da aula 12) | `bash -c 'tar czf - -C aula-12 scripts/demo-migrations.sh \| ssh -i ~/.ssh/technova-aula10-deploy.pem -o LogLevel=ERROR ec2-user@44.204.33.200 '"'"'tar xzf - -C mig && cd mig && bash scripts/demo-migrations.sh'"'"''` | ✅ 0 | [001_194203_migracoes-expand-contract-status-up-down.txt](001_194203_migracoes-expand-contract-status-up-down.txt) — TXT — saída real do processo<br>[001_194203_migracoes-expand-contract-status-up-down_renderizada.png](001_194203_migracoes-expand-contract-status-up-down_renderizada.png) — PNG — imagem renderizada (não é captura de tela) |
| 002 | 19:42:21 | Feature flag FF_NEW_SHIPPING_CALC ligada e desligada (rollback de feature sem redeploy) | `bash -c 'cd aula-12 && bash scripts/demo-flags.sh'` | ❌ 143 | [002_194221_feature-flag-ff-new-shipping-calc-ligada.txt](002_194221_feature-flag-ff-new-shipping-calc-ligada.txt) — TXT — saída real do processo<br>[002_194221_feature-flag-ff-new-shipping-calc-ligada_renderizada.png](002_194221_feature-flag-ff-new-shipping-calc-ligada_renderizada.png) — PNG — imagem renderizada (não é captura de tela) |
| 003 | 19:42:51 | Feature flag FF_NEW_SHIPPING_CALC ligada e desligada (rollback de feature sem redeploy) - reexecucao com retorno 0 | `bash -c 'cd aula-12 && bash scripts/demo-flags.sh'` | ✅ 0 | [003_194251_feature-flag-ff-new-shipping-calc-ligada.txt](003_194251_feature-flag-ff-new-shipping-calc-ligada.txt) — TXT — saída real do processo<br>[003_194251_feature-flag-ff-new-shipping-calc-ligada_renderizada.png](003_194251_feature-flag-ff-new-shipping-calc-ligada_renderizada.png) — PNG — imagem renderizada (não é captura de tela) |
| 004 | 19:43:20 | Invocacao da Lambda TechNovaAIOpsAnalyzer (LabRole) com evento de alarme de teste | `bash -c 'aws lambda invoke --function-name TechNovaAIOpsAnalyzer --payload fileb://aula-12/lambda-aiops/test-event.json /tmp/aiops-response.json --query '"'"'[StatusCode,FunctionError]'"'"' --output text && jq . /tmp/aiops-response.json && aws lambda get-function-configuration --function-name TechNovaAIOpsAnalyzer --query '"'"'{Role:Role,Runtime:Runtime}'"'"' --output table'` | ❌ 127 | [004_194320_invocacao-da-lambda-technovaaiopsanalyze.txt](004_194320_invocacao-da-lambda-technovaaiopsanalyze.txt) — TXT — saída real do processo<br>[004_194320_invocacao-da-lambda-technovaaiopsanalyze_renderizada.png](004_194320_invocacao-da-lambda-technovaaiopsanalyze_renderizada.png) — PNG — imagem renderizada (não é captura de tela) |
| 005 | 19:43:30 | Invocacao da Lambda TechNovaAIOpsAnalyzer (LabRole) com evento de alarme de teste - com python para formatar | `bash -c 'aws lambda invoke --function-name TechNovaAIOpsAnalyzer --payload fileb://aula-12/lambda-aiops/test-event.json /tmp/aiops-response.json --query '"'"'[StatusCode,FunctionError]'"'"' --output text && python3 -m json.tool --no-ensure-ascii /tmp/aiops-response.json && aws lambda get-function-configuration --function-name TechNovaAIOpsAnalyzer --query '"'"'{Role:Role,Runtime:Runtime}'"'"' --output table'` | ✅ 0 | [005_194330_invocacao-da-lambda-technovaaiopsanalyze.txt](005_194330_invocacao-da-lambda-technovaaiopsanalyze.txt) — TXT — saída real do processo<br>[005_194330_invocacao-da-lambda-technovaaiopsanalyze_renderizada.png](005_194330_invocacao-da-lambda-technovaaiopsanalyze_renderizada.png) — PNG — imagem renderizada (não é captura de tela) |
| 007 | 19:46:03 | Forca metricas altas no CloudWatch (TechNova/API) para disparar os alarmes e a Lambda AIOps via EventBridge | `bash aula-12/scripts/force-alarm.sh 5` | ✅ 0 | [007_194603_forca-metricas-altas-no-cloudwatch-techn.txt](007_194603_forca-metricas-altas-no-cloudwatch-techn.txt) — TXT — saída real do processo<br>[007_194603_forca-metricas-altas-no-cloudwatch-techn_renderizada.png](007_194603_forca-metricas-altas-no-cloudwatch-techn_renderizada.png) — PNG — imagem renderizada (não é captura de tela) |
| 008 | 20:14:29 | Log real do rollback automatico da aula 12 (run 42310191161, simulate_failure=true) | `bash -c 'gh run view 42310191161 -R lucaskenway/unifaat-devops-portfolio --log \| sed '"'"'s/^[^\t]*\t[^\t]*\t//'"'"' \| grep -vE '"'"'\[36;1m\|^ +[A-Z_]+: '"'"' \| grep -E '"'"'Em produção\|Subindo\|check [0-9]\|Resultado\|FAILED\|PASSED\|ROLLBACK\|Versão alvo\|MessageId\|REVERTIDO'"'"''` | ✅ 0 | [008_201429_log-real-do-rollback-automatico-da-aula.txt](008_201429_log-real-do-rollback-automatico-da-aula.txt) — TXT — saída real do processo<br>[008_201429_log-real-do-rollback-automatico-da-aula_renderizada.png](008_201429_log-real-do-rollback-automatico-da-aula_renderizada.png) — PNG — imagem renderizada (não é captura de tela) |
| 009 | 20:17:31 | Simulador local AIOps (sem Bedrock): 3 cenarios de incidente com analise, decisao de rollback e post-mortem | `bash -c 'node aula-12/lambda-aiops/local-simulator.js all \| grep -vE '"'"'^   (ERROR\|WARN\|INFO\|FATAL)'"'"' \| grep -vE '"'"'^\s+"(evidencias\|causa_raiz\|acao)'"'"' '` | ✅ 0 | [009_201731_simulador-local-aiops-sem-bedrock-3-cena.txt](009_201731_simulador-local-aiops-sem-bedrock-3-cena.txt) — TXT — saída real do processo<br>[009_201731_simulador-local-aiops-sem-bedrock-3-cena_renderizada.png](009_201731_simulador-local-aiops-sem-bedrock-3-cena_renderizada.png) — PNG — imagem renderizada (não é captura de tela) |
| 010 | 20:17:40 | Feature flag em producao na EC2: FF_NEW_SHIPPING_CALC=false via toggle-flag.sh (mesma imagem, sem pipeline) e volta para true | `bash -c 'B='"'"'{"items":[{"name":"Widget","price":29.9,"weight":0.3}]}'"'"'; scp -q -i ~/.ssh/technova-aula10-deploy.pem -o LogLevel=ERROR aula-12/scripts/toggle-flag.sh ec2-user@44.204.33.200:/tmp/; for v in true false true; do echo; echo "### FF_NEW_SHIPPING_CALC=$v"; ssh -i ~/.ssh/technova-aula10-deploy.pem -o LogLevel=ERROR ec2-user@44.204.33.200 "bash /tmp/toggle-flag.sh FF_NEW_SHIPPING_CALC $v"; echo "\$ curl -X POST http://44.204.33.200:3000/api/orders"; curl -s -X POST http://44.204.33.200:3000/api/orders -H '"'"'Content-Type: application/json'"'"' -d "$B" \| python3 -c '"'"'import json,sys;o=json.load(sys.stdin);print({k:o[k] for k in ("shippingMethod","shipping","total")})'"'"'; done; echo; echo "\$ curl http://44.204.33.200:3000/flags"; curl -s -w '"'"' (HTTP %{http_code})\n'"'"' http://44.204.33.200:3000/flags'` | ✅ 0 | [010_201740_feature-flag-em-producao-na-ec2-ff-new-s.txt](010_201740_feature-flag-em-producao-na-ec2-ff-new-s.txt) — TXT — saída real do processo<br>[010_201740_feature-flag-em-producao-na-ec2-ff-new-s_renderizada.png](010_201740_feature-flag-em-producao-na-ec2-ff-new-s_renderizada.png) — PNG — imagem renderizada (não é captura de tela) |

## Detalhes

### #001 — Migracoes expand-contract: status, up, down 001, down 000, up de novo (Postgres na EC2 da aula 12)

- **Comando:** `bash -c 'tar czf - -C aula-12 scripts/demo-migrations.sh | ssh -i ~/.ssh/technova-aula10-deploy.pem -o LogLevel=ERROR ec2-user@44.204.33.200 '"'"'tar xzf - -C mig && cd mig && bash scripts/demo-migrations.sh'"'"''`
- **Shell:** direto · **diretório:** `/mnt/c/Users/lucas/portfolio-aula12`
- **Início:** 2026-11-06T19:42:03-03:00 · **fim:** 2026-11-06T19:42:09-03:00 · **duração:** 6.216 s
- **Código de retorno:** 0
- `001_194203_migracoes-expand-contract-status-up-down.txt` — TXT — saída real do processo — SHA-256 `c67610ba14edf81c41fedcae564cdf6d3686787caa61dff2fa18a98ed5bec686`
- `001_194203_migracoes-expand-contract-status-up-down_renderizada.png` — PNG — imagem renderizada (não é captura de tela) — SHA-256 `e6dfb04f427c73d23e12901c7d4505e5c4642bcbfbbd0009c3dd9e40c4fc086a`

### #002 — Feature flag FF_NEW_SHIPPING_CALC ligada e desligada (rollback de feature sem redeploy)

- **Comando:** `bash -c 'cd aula-12 && bash scripts/demo-flags.sh'`
- **Shell:** direto · **diretório:** `/mnt/c/Users/lucas/portfolio-aula12`
- **Início:** 2026-11-06T19:42:21-03:00 · **fim:** 2026-11-06T19:42:43-03:00 · **duração:** 22.515 s
- **Código de retorno:** 143
- `002_194221_feature-flag-ff-new-shipping-calc-ligada.txt` — TXT — saída real do processo — SHA-256 `8503ac11bc36ffe84140a7410d4aa56136725aba04248d154e35d8488800266f`
- `002_194221_feature-flag-ff-new-shipping-calc-ligada_renderizada.png` — PNG — imagem renderizada (não é captura de tela) — SHA-256 `d37b68bbbd33f798ebe4ffb9fd5517e54ce1d106303ba5e1746d6d27377fd862`

### #003 — Feature flag FF_NEW_SHIPPING_CALC ligada e desligada (rollback de feature sem redeploy) - reexecucao com retorno 0

- **Comando:** `bash -c 'cd aula-12 && bash scripts/demo-flags.sh'`
- **Shell:** direto · **diretório:** `/mnt/c/Users/lucas/portfolio-aula12`
- **Início:** 2026-11-06T19:42:51-03:00 · **fim:** 2026-11-06T19:43:06-03:00 · **duração:** 14.867 s
- **Código de retorno:** 0
- `003_194251_feature-flag-ff-new-shipping-calc-ligada.txt` — TXT — saída real do processo — SHA-256 `e88232760a87ca4789168328efecdde9374cf65ee1401bc87c3943b1fd4c4647`
- `003_194251_feature-flag-ff-new-shipping-calc-ligada_renderizada.png` — PNG — imagem renderizada (não é captura de tela) — SHA-256 `f4053e33e47bfc39654046b3026215f32416c41bd40da02453f51d07dcb69fde`

### #004 — Invocacao da Lambda TechNovaAIOpsAnalyzer (LabRole) com evento de alarme de teste

- **Comando:** `bash -c 'aws lambda invoke --function-name TechNovaAIOpsAnalyzer --payload fileb://aula-12/lambda-aiops/test-event.json /tmp/aiops-response.json --query '"'"'[StatusCode,FunctionError]'"'"' --output text && jq . /tmp/aiops-response.json && aws lambda get-function-configuration --function-name TechNovaAIOpsAnalyzer --query '"'"'{Role:Role,Runtime:Runtime}'"'"' --output table'`
- **Shell:** direto · **diretório:** `/mnt/c/Users/lucas/portfolio-aula12`
- **Início:** 2026-11-06T19:43:20-03:00 · **fim:** 2026-11-06T19:43:24-03:00 · **duração:** 3.709 s
- **Código de retorno:** 127
- `004_194320_invocacao-da-lambda-technovaaiopsanalyze.txt` — TXT — saída real do processo — SHA-256 `c77db5b6e04f012b5fece87a1ea9cded2c364aa94928811d4f38ed069073b87d`
- `004_194320_invocacao-da-lambda-technovaaiopsanalyze_renderizada.png` — PNG — imagem renderizada (não é captura de tela) — SHA-256 `1d1863f9ab53cdf34014e5369aa3f3aaf11ceacf9547851c32c87533f6c5be01`

### #005 — Invocacao da Lambda TechNovaAIOpsAnalyzer (LabRole) com evento de alarme de teste - com python para formatar

- **Comando:** `bash -c 'aws lambda invoke --function-name TechNovaAIOpsAnalyzer --payload fileb://aula-12/lambda-aiops/test-event.json /tmp/aiops-response.json --query '"'"'[StatusCode,FunctionError]'"'"' --output text && python3 -m json.tool --no-ensure-ascii /tmp/aiops-response.json && aws lambda get-function-configuration --function-name TechNovaAIOpsAnalyzer --query '"'"'{Role:Role,Runtime:Runtime}'"'"' --output table'`
- **Shell:** direto · **diretório:** `/mnt/c/Users/lucas/portfolio-aula12`
- **Início:** 2026-11-06T19:43:30-03:00 · **fim:** 2026-11-06T19:43:34-03:00 · **duração:** 3.849 s
- **Código de retorno:** 0
- `005_194330_invocacao-da-lambda-technovaaiopsanalyze.txt` — TXT — saída real do processo — SHA-256 `811eae1c2c46ee2ec19f7feb95b59701ba3cbc2c1b103d954c8217661e2c892a`
- `005_194330_invocacao-da-lambda-technovaaiopsanalyze_renderizada.png` — PNG — imagem renderizada (não é captura de tela) — SHA-256 `0f20b339bfc5632a74a8c0fd69717f0b20636f8033362012606995e53b08e8df`

### #007 — Forca metricas altas no CloudWatch (TechNova/API) para disparar os alarmes e a Lambda AIOps via EventBridge

- **Comando:** `bash aula-12/scripts/force-alarm.sh 5`
- **Shell:** direto · **diretório:** `/mnt/c/Users/lucas/portfolio-aula12`
- **Início:** 2026-11-06T19:46:03-03:00 · **fim:** 2026-11-06T19:51:22-03:00 · **duração:** 318.812 s
- **Código de retorno:** 0
- `007_194603_forca-metricas-altas-no-cloudwatch-techn.txt` — TXT — saída real do processo — SHA-256 `abe4895455bce8af23b9c6fccf40b49b0020fdc814083d4f0a3197a6ab223975`
- `007_194603_forca-metricas-altas-no-cloudwatch-techn_renderizada.png` — PNG — imagem renderizada (não é captura de tela) — SHA-256 `e7be5a4eb8420053bd00eaf9094e25ee441947bfcaeb075b3cdcb5efc87c2f86`

### #008 — Log real do rollback automatico da aula 12 (run 42310191161, simulate_failure=true)

- **Comando:** `bash -c 'gh run view 42310191161 -R lucaskenway/unifaat-devops-portfolio --log | sed '"'"'s/^[^\t]*\t[^\t]*\t//'"'"' | grep -vE '"'"'\[36;1m|^ +[A-Z_]+: '"'"' | grep -E '"'"'Em produção|Subindo|check [0-9]|Resultado|FAILED|PASSED|ROLLBACK|Versão alvo|MessageId|REVERTIDO'"'"''`
- **Shell:** direto · **diretório:** `/mnt/c/Users/lucas/portfolio-aula12`
- **Início:** 2026-11-06T20:14:29-03:00 · **fim:** 2026-11-06T20:14:32-03:00 · **duração:** 2.956 s
- **Código de retorno:** 0
- `008_201429_log-real-do-rollback-automatico-da-aula.txt` — TXT — saída real do processo — SHA-256 `3506ceba84cda6bcc4be53fb0f2bcd9de2e441237c32fda6875199bca9d30248`
- `008_201429_log-real-do-rollback-automatico-da-aula_renderizada.png` — PNG — imagem renderizada (não é captura de tela) — SHA-256 `c888332457c96055b06575c3b789e41f831b577effca3f53803c6cbabcd4b7b7`

### #009 — Simulador local AIOps (sem Bedrock): 3 cenarios de incidente com analise, decisao de rollback e post-mortem

- **Comando:** `bash -c 'node aula-12/lambda-aiops/local-simulator.js all | grep -vE '"'"'^   (ERROR|WARN|INFO|FATAL)'"'"' | grep -vE '"'"'^\s+"(evidencias|causa_raiz|acao)'"'"' '`
- **Shell:** direto · **diretório:** `/mnt/c/Users/lucas/portfolio-aula12`
- **Início:** 2026-11-06T20:17:31-03:00 · **fim:** 2026-11-06T20:17:31-03:00 · **duração:** 0.407 s
- **Código de retorno:** 0
- `009_201731_simulador-local-aiops-sem-bedrock-3-cena.txt` — TXT — saída real do processo — SHA-256 `6bc4b7923168cbfd83a0689560083ec0a48196a0f483a9550c0c8f9bc4a329f5`
- `009_201731_simulador-local-aiops-sem-bedrock-3-cena_renderizada.png` — PNG — imagem renderizada (não é captura de tela) — SHA-256 `c15bbdf91b06ee5333fd36b10c09ae77430519f2fc234adeb5dcc2dc06219382`

### #010 — Feature flag em producao na EC2: FF_NEW_SHIPPING_CALC=false via toggle-flag.sh (mesma imagem, sem pipeline) e volta para true

- **Comando:** `bash -c 'B='"'"'{"items":[{"name":"Widget","price":29.9,"weight":0.3}]}'"'"'; scp -q -i ~/.ssh/technova-aula10-deploy.pem -o LogLevel=ERROR aula-12/scripts/toggle-flag.sh ec2-user@44.204.33.200:/tmp/; for v in true false true; do echo; echo "### FF_NEW_SHIPPING_CALC=$v"; ssh -i ~/.ssh/technova-aula10-deploy.pem -o LogLevel=ERROR ec2-user@44.204.33.200 "bash /tmp/toggle-flag.sh FF_NEW_SHIPPING_CALC $v"; echo "\$ curl -X POST http://44.204.33.200:3000/api/orders"; curl -s -X POST http://44.204.33.200:3000/api/orders -H '"'"'Content-Type: application/json'"'"' -d "$B" | python3 -c '"'"'import json,sys;o=json.load(sys.stdin);print({k:o[k] for k in ("shippingMethod","shipping","total")})'"'"'; done; echo; echo "\$ curl http://44.204.33.200:3000/flags"; curl -s -w '"'"' (HTTP %{http_code})\n'"'"' http://44.204.33.200:3000/flags'`
- **Shell:** direto · **diretório:** `/mnt/c/Users/lucas/portfolio-aula12`
- **Início:** 2026-11-06T20:17:40-03:00 · **fim:** 2026-11-06T20:17:58-03:00 · **duração:** 18.142 s
- **Código de retorno:** 0
- `010_201740_feature-flag-em-producao-na-ec2-ff-new-s.txt` — TXT — saída real do processo — SHA-256 `d892fd761c355d06d9015981f6485fe18169e20eb14ec993f8639d85a0dd6ea7`
- `010_201740_feature-flag-em-producao-na-ec2-ff-new-s_renderizada.png` — PNG — imagem renderizada (não é captura de tela) — SHA-256 `a4591bc938e8db630f3ad26e05143118cdfe679baba958183d75d12690cf6401`

## Verificação de integridade

- ✅ Todos os arquivos existem e conferem com o SHA-256 registrado.
