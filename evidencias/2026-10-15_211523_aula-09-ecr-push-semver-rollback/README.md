# Evidências — aula-09 ecr push semver rollback

- **Projeto:** `unifaat-devops-portfolio`
- **Início da sessão:** 2026-10-15T21:15:23-03:00
- **Fim da sessão:** 2026-10-15T21:26:36-03:00
- **Ambiente:** WSL (Ubuntu) Ubuntu 26.04 LTS · usuário `lucaskenway` · host `DESKTOP-AMJ5UEC`
- **Comandos registrados:** 13 (11 com retorno 0, 2 com falha) · **capturas de tela:** 0

> Gerado pela ferramenta `evidencia`. Os TXT contêm a saída capturada diretamente dos processos, sem edição; a única alteração possível é a troca de dados sensíveis por `[REDIGIDO:tipo]`, sempre informada abaixo. Imagens **renderizadas** são desenhadas a partir do TXT e **não são capturas de tela**; capturas **autênticas** são cópias dos pixels da tela.

## Índice

| # | Horário | Descrição | Comando | Retorno | Arquivos |
|---|---------|-----------|---------|---------|----------|
| 001 | 21:15:24 | ecr-push.sh: cria repo, login, build e push sha + latest | `./ecr-push.sh` | ✅ 0 | [001_211524_ecr-push-sh-cria-repo-login-build-e-push.txt](001_211524_ecr-push-sh-cria-repo-login-build-e-push.txt) — TXT — saída real do processo<br>[001_211524_ecr-push-sh-cria-repo-login-build-e-push_renderizada.png](001_211524_ecr-push-sh-cria-repo-login-build-e-push_renderizada.png) — PNG — imagem renderizada (não é captura de tela) |
| 002 | 21:17:08 | ecr-push.sh com git tag v1.0.0: publica 1.0.0, 1.0, 1, sha e latest | `./ecr-push.sh` | ✅ 0 | [002_211708_ecr-push-sh-com-git-tag-v1-0-0-publica-1.txt](002_211708_ecr-push-sh-com-git-tag-v1-0-0-publica-1.txt) — TXT — saída real do processo<br>[002_211708_ecr-push-sh-com-git-tag-v1-0-0-publica-1_renderizada.png](002_211708_ecr-push-sh-com-git-tag-v1-0-0-publica-1_renderizada.png) — PNG — imagem renderizada (não é captura de tela) |
| 003 | 21:17:49 | ecr-rollback.sh 1.0.0: pull do ECR, run e health check | `./ecr-rollback.sh 1.0.0` | ❌ 125 | [003_211749_ecr-rollback-sh-1-0-0-pull-do-ecr-run-e.txt](003_211749_ecr-rollback-sh-1-0-0-pull-do-ecr-run-e.txt) — TXT — saída real do processo<br>[003_211749_ecr-rollback-sh-1-0-0-pull-do-ecr-run-e_renderizada.png](003_211749_ecr-rollback-sh-1-0-0-pull-do-ecr-run-e_renderizada.png) — PNG — imagem renderizada (não é captura de tela) |
| 004 | 21:18:03 | ecr-rollback.sh sha-7131e31: rollback para o build anterior | `./ecr-rollback.sh sha-7131e31` | ❌ 125 | [004_211803_ecr-rollback-sh-sha-7131e31-rollback-par.txt](004_211803_ecr-rollback-sh-sha-7131e31-rollback-par.txt) — TXT — saída real do processo<br>[004_211803_ecr-rollback-sh-sha-7131e31-rollback-par_renderizada.png](004_211803_ecr-rollback-sh-sha-7131e31-rollback-par_renderizada.png) — PNG — imagem renderizada (não é captura de tela) |
| 005 | 21:18:35 | PORT=3009 ecr-rollback.sh 1.0.0: pull do ECR, run e health check | `env PORT=3009 ./ecr-rollback.sh 1.0.0` | ✅ 0 | [005_211835_port-3009-ecr-rollback-sh-1-0-0-pull-do.txt](005_211835_port-3009-ecr-rollback-sh-1-0-0-pull-do.txt) — TXT — saída real do processo<br>[005_211835_port-3009-ecr-rollback-sh-1-0-0-pull-do_renderizada.png](005_211835_port-3009-ecr-rollback-sh-1-0-0-pull-do_renderizada.png) — PNG — imagem renderizada (não é captura de tela) |
| 006 | 21:18:44 | PORT=3009 ecr-rollback.sh sha-7131e31: pull do ECR, run e health check | `env PORT=3009 ./ecr-rollback.sh sha-7131e31` | ✅ 0 | [006_211844_port-3009-ecr-rollback-sh-sha-7131e31-pu.txt](006_211844_port-3009-ecr-rollback-sh-sha-7131e31-pu.txt) — TXT — saída real do processo<br>[006_211844_port-3009-ecr-rollback-sh-sha-7131e31-pu_renderizada.png](006_211844_port-3009-ecr-rollback-sh-sha-7131e31-pu_renderizada.png) — PNG — imagem renderizada (não é captura de tela) |
| 007 | 21:18:59 | PORT=3009 ecr-rollback.sh 1.0.0: pull do ECR, run e health check | `env PORT=3009 ./ecr-rollback.sh 1.0.0` | ✅ 0 | [007_211859_port-3009-ecr-rollback-sh-1-0-0-pull-do.txt](007_211859_port-3009-ecr-rollback-sh-1-0-0-pull-do.txt) — TXT — saída real do processo<br>[007_211859_port-3009-ecr-rollback-sh-1-0-0-pull-do_renderizada.png](007_211859_port-3009-ecr-rollback-sh-1-0-0-pull-do_renderizada.png) — PNG — imagem renderizada (não é captura de tela) |
| 008 | 21:19:23 | Tags no ECR (describe-images) | `aws ecr describe-images --repository-name technova-api --region us-east-1 --query 'sort_by(imageDetails,&imagePushedAt)[].{Tags:join('"'"', '"'"',imageTags),Digest:imageDigest,Scan:imageScanStatus.status}' --output table` | ✅ 0 | [008_211923_tags-no-ecr-describe-images.txt](008_211923_tags-no-ecr-describe-images.txt) — TXT — saída real do processo<br>[008_211923_tags-no-ecr-describe-images_renderizada.png](008_211923_tags-no-ecr-describe-images_renderizada.png) — PNG — imagem renderizada (não é captura de tela) |
| 009 | 21:19:25 | Scan on push do ECR: resultado da release 1.0.0 | `aws ecr describe-image-scan-findings --repository-name technova-api --image-id imageTag=1.0.0 --region us-east-1 --query '{status:imageScanStatus.status,severidades:imageScanFindings.findingSeverityCounts,concluido:imageScanFindings.imageScanCompletedAt}' --output json` | ✅ 0 | [009_211925_scan-on-push-do-ecr-resultado-da-release.txt](009_211925_scan-on-push-do-ecr-resultado-da-release.txt) — TXT — saída real do processo<br>[009_211925_scan-on-push-do-ecr-resultado-da-release_renderizada.png](009_211925_scan-on-push-do-ecr-resultado-da-release_renderizada.png) — PNG — imagem renderizada (não é captura de tela) |
| 010 | 21:19:27 | Configuracao do repositorio: scan on push e lifecycle policy | `bash -c 'aws ecr describe-repositories --repository-names technova-api --region us-east-1 --query "repositories[0].{uri:repositoryUri,scanOnPush:imageScanningConfiguration.scanOnPush,mutabilidade:imageTagMutability}" --output table && aws ecr get-lifecycle-policy --repository-name technova-api --region us-east-1 --query lifecyclePolicyText --output text'` | ✅ 0 | [010_211927_configuracao-do-repositorio-scan-on-push.txt](010_211927_configuracao-do-repositorio-scan-on-push.txt) — TXT — saída real do processo<br>[010_211927_configuracao-do-repositorio-scan-on-push_renderizada.png](010_211927_configuracao-do-repositorio-scan-on-push_renderizada.png) — PNG — imagem renderizada (não é captura de tela) |
| 011 | 21:21:47 | Teste de acesso ao Amazon Bedrock no Learner Lab (Converse) | `bash -c 'for m in anthropic.claude-3-haiku-20240307-v1:0 us.anthropic.claude-haiku-4-5-20251001-v1:0 amazon.nova-micro-v1:0; do echo "== $m"; aws bedrock-runtime converse --region us-east-1 --model-id "$m" --messages "[{\"role\":\"user\",\"content\":[{\"text\":\"ok\"}]}]" --inference-config "{\"maxTokens\":5}" 2>&1 \| sed "s/.*operation: //"; done; true'` | ✅ 0 | [011_212147_teste-de-acesso-ao-amazon-bedrock-no-lea.txt](011_212147_teste-de-acesso-ao-amazon-bedrock-no-lea.txt) — TXT — saída real do processo<br>[011_212147_teste-de-acesso-ao-amazon-bedrock-no-lea_renderizada.png](011_212147_teste-de-acesso-ao-amazon-bedrock-no-lea_renderizada.png) — PNG — imagem renderizada (não é captura de tela) |
| 012 | 21:26:31 | ai-review.js com Bedrock real no Lab: fallback para regras | `bash -c 'BEDROCK_MODEL_ID=us.anthropic.claude-haiku-4-5-20251001-v1:0 DIFF_FILE=aula-09/exemplos/pr-inseguro.diff REVIEW_OUTPUT=/tmp/claude-1000/-mnt-c-Users-lucas-devops-20262/0a372ff8-8d7b-4bff-93e9-f177175996bc/scratchpad/ev1.md node .github/scripts/ai-review.js \| grep -E '"'"'Bedrock\|indisponível\|Análise concluída\|fallback'"'"''` | ✅ 0 | [012_212631_ai-review-js-com-bedrock-real-no-lab-fal.txt](012_212631_ai-review-js-com-bedrock-real-no-lab-fal.txt) — TXT — saída real do processo<br>[012_212631_ai-review-js-com-bedrock-real-no-lab-fal_renderizada.png](012_212631_ai-review-js-com-bedrock-real-no-lab-fal_renderizada.png) — PNG — imagem renderizada (não é captura de tela) |
| 013 | 21:26:34 | ai-review.js com resposta SIMULADA do Bedrock (aws falso no PATH): parse e tabela do LLM | `bash -c 'PATH=/tmp/claude-1000/-mnt-c-Users-lucas-devops-20262/0a372ff8-8d7b-4bff-93e9-f177175996bc/scratchpad/fakebin:$PATH BEDROCK_MODEL_ID=modelo-simulado DIFF_FILE=aula-09/exemplos/pr-inseguro.diff REVIEW_OUTPUT=/tmp/claude-1000/-mnt-c-Users-lucas-devops-20262/0a372ff8-8d7b-4bff-93e9-f177175996bc/scratchpad/ev2.md node .github/scripts/ai-review.js >/dev/null; sed -n '"'"'/Análise do LLM/,/^---/p'"'"' /tmp/claude-1000/-mnt-c-Users-lucas-devops-20262/0a372ff8-8d7b-4bff-93e9-f177175996bc/scratchpad/ev2.md'` | ✅ 0 | [013_212634_ai-review-js-com-resposta-simulada-do-be.txt](013_212634_ai-review-js-com-resposta-simulada-do-be.txt) — TXT — saída real do processo<br>[013_212634_ai-review-js-com-resposta-simulada-do-be_renderizada.png](013_212634_ai-review-js-com-resposta-simulada-do-be_renderizada.png) — PNG — imagem renderizada (não é captura de tela) |

## Detalhes

### #001 — ecr-push.sh: cria repo, login, build e push sha + latest

- **Comando:** `./ecr-push.sh`
- **Shell:** bash · **diretório:** `/mnt/c/Users/lucas/unifaat-devops-portfolio/aula-09/technova-api`
- **Início:** 2026-10-15T21:15:24-03:00 · **fim:** 2026-10-15T21:16:23-03:00 · **duração:** 58.870 s
- **Código de retorno:** 0
- `001_211524_ecr-push-sh-cria-repo-login-build-e-push.txt` — TXT — saída real do processo — SHA-256 `345527a623daea63a6b6027cd84debda43d6c01388b009527b7cb1ba7340628d`
- `001_211524_ecr-push-sh-cria-repo-login-build-e-push_renderizada.png` — PNG — imagem renderizada (não é captura de tela) — SHA-256 `b522072292e1ae60d48499bc990ec749c6833a1a0ed99fb544e612b386ebd4c1`

### #002 — ecr-push.sh com git tag v1.0.0: publica 1.0.0, 1.0, 1, sha e latest

- **Comando:** `./ecr-push.sh`
- **Shell:** bash · **diretório:** `/mnt/c/Users/lucas/unifaat-devops-portfolio/aula-09/technova-api`
- **Início:** 2026-10-15T21:17:08-03:00 · **fim:** 2026-10-15T21:17:35-03:00 · **duração:** 26.308 s
- **Código de retorno:** 0
- `002_211708_ecr-push-sh-com-git-tag-v1-0-0-publica-1.txt` — TXT — saída real do processo — SHA-256 `85d76bdbb8ffd1a0db6e3563045902ecf4c6f02c410791f5f1911151339a2704`
- `002_211708_ecr-push-sh-com-git-tag-v1-0-0-publica-1_renderizada.png` — PNG — imagem renderizada (não é captura de tela) — SHA-256 `07fa31ec1ef7557021ddf7f03b585c2c1ccbdc0c6eddcac9fdf4d0f2894661b0`

### #003 — ecr-rollback.sh 1.0.0: pull do ECR, run e health check

- **Comando:** `./ecr-rollback.sh 1.0.0`
- **Shell:** direto · **diretório:** `/mnt/c/Users/lucas/unifaat-devops-portfolio/aula-09/technova-api`
- **Início:** 2026-10-15T21:17:49-03:00 · **fim:** 2026-10-15T21:18:01-03:00 · **duração:** 12.101 s
- **Código de retorno:** 125
- `003_211749_ecr-rollback-sh-1-0-0-pull-do-ecr-run-e.txt` — TXT — saída real do processo — SHA-256 `0a485e7d364e0f645ccc9638ae80182610a74c7edd5c22b3815f39a4eb710238`
- `003_211749_ecr-rollback-sh-1-0-0-pull-do-ecr-run-e_renderizada.png` — PNG — imagem renderizada (não é captura de tela) — SHA-256 `c886efaa9e83ced33429e725fd838c4c6ea91348ba0fed119376ab5b05ecb8bb`

### #004 — ecr-rollback.sh sha-7131e31: rollback para o build anterior

- **Comando:** `./ecr-rollback.sh sha-7131e31`
- **Shell:** direto · **diretório:** `/mnt/c/Users/lucas/unifaat-devops-portfolio/aula-09/technova-api`
- **Início:** 2026-10-15T21:18:03-03:00 · **fim:** 2026-10-15T21:18:15-03:00 · **duração:** 12.191 s
- **Código de retorno:** 125
- `004_211803_ecr-rollback-sh-sha-7131e31-rollback-par.txt` — TXT — saída real do processo — SHA-256 `1ccb9faf12c0fb35e27c29f8a9d023c403b40eeb719c25a251b6328d6a45d154`
- `004_211803_ecr-rollback-sh-sha-7131e31-rollback-par_renderizada.png` — PNG — imagem renderizada (não é captura de tela) — SHA-256 `3b176110d88519cadea92a46c22a5d6257e2c9b823ff62c17ae0c05daa476de1`

### #005 — PORT=3009 ecr-rollback.sh 1.0.0: pull do ECR, run e health check

- **Comando:** `env PORT=3009 ./ecr-rollback.sh 1.0.0`
- **Shell:** direto · **diretório:** `/mnt/c/Users/lucas/unifaat-devops-portfolio/aula-09/technova-api`
- **Início:** 2026-10-15T21:18:35-03:00 · **fim:** 2026-10-15T21:18:43-03:00 · **duração:** 8.676 s
- **Código de retorno:** 0
- `005_211835_port-3009-ecr-rollback-sh-1-0-0-pull-do.txt` — TXT — saída real do processo — SHA-256 `b95c9dbdcaf595e070c2e0c7fccacca09ade1fc49ba4e3235d30d47eef57920e`
- `005_211835_port-3009-ecr-rollback-sh-1-0-0-pull-do_renderizada.png` — PNG — imagem renderizada (não é captura de tela) — SHA-256 `9ac62fbed97e67804a2b7c3f5d210af9f157496128c32b088e4632e0c44182d0`

### #006 — PORT=3009 ecr-rollback.sh sha-7131e31: pull do ECR, run e health check

- **Comando:** `env PORT=3009 ./ecr-rollback.sh sha-7131e31`
- **Shell:** direto · **diretório:** `/mnt/c/Users/lucas/unifaat-devops-portfolio/aula-09/technova-api`
- **Início:** 2026-10-15T21:18:44-03:00 · **fim:** 2026-10-15T21:18:59-03:00 · **duração:** 14.850 s
- **Código de retorno:** 0
- `006_211844_port-3009-ecr-rollback-sh-sha-7131e31-pu.txt` — TXT — saída real do processo — SHA-256 `66b4e10e5bf0c47b16ea8c5d3638a44e79b85cc8e7a007a2ac7f0fde9cbdb2ef`
- `006_211844_port-3009-ecr-rollback-sh-sha-7131e31-pu_renderizada.png` — PNG — imagem renderizada (não é captura de tela) — SHA-256 `23aaa7cb2490ab0c98cb271c6c240a76099764fb4a38daaeccd56b0f82c9eb5d`

### #007 — PORT=3009 ecr-rollback.sh 1.0.0: pull do ECR, run e health check

- **Comando:** `env PORT=3009 ./ecr-rollback.sh 1.0.0`
- **Shell:** direto · **diretório:** `/mnt/c/Users/lucas/unifaat-devops-portfolio/aula-09/technova-api`
- **Início:** 2026-10-15T21:18:59-03:00 · **fim:** 2026-10-15T21:19:07-03:00 · **duração:** 7.764 s
- **Código de retorno:** 0
- `007_211859_port-3009-ecr-rollback-sh-1-0-0-pull-do.txt` — TXT — saída real do processo — SHA-256 `248932c1c482757c2bd5e923c39488a59d2b717617f5eb9322c2440f3b48b998`
- `007_211859_port-3009-ecr-rollback-sh-1-0-0-pull-do_renderizada.png` — PNG — imagem renderizada (não é captura de tela) — SHA-256 `ff2db084174622d718d7e78afc696061b8c4661a9212264a817d9c0bdcdba034`

### #008 — Tags no ECR (describe-images)

- **Comando:** `aws ecr describe-images --repository-name technova-api --region us-east-1 --query 'sort_by(imageDetails,&imagePushedAt)[].{Tags:join('"'"', '"'"',imageTags),Digest:imageDigest,Scan:imageScanStatus.status}' --output table`
- **Shell:** direto · **diretório:** `/mnt/c/Users/lucas/unifaat-devops-portfolio/aula-09/technova-api`
- **Início:** 2026-10-15T21:19:23-03:00 · **fim:** 2026-10-15T21:19:24-03:00 · **duração:** 1.397 s
- **Código de retorno:** 0
- `008_211923_tags-no-ecr-describe-images.txt` — TXT — saída real do processo — SHA-256 `97a80cd802e2fcf36dab80b33daf0752f2b4c85c4c1db0a835a78de1d81e225a`
- `008_211923_tags-no-ecr-describe-images_renderizada.png` — PNG — imagem renderizada (não é captura de tela) — SHA-256 `de5822b27ff9ccc491cf887a8556d49af30f8bc6adca8403af6b7e62d0d88ace`

### #009 — Scan on push do ECR: resultado da release 1.0.0

- **Comando:** `aws ecr describe-image-scan-findings --repository-name technova-api --image-id imageTag=1.0.0 --region us-east-1 --query '{status:imageScanStatus.status,severidades:imageScanFindings.findingSeverityCounts,concluido:imageScanFindings.imageScanCompletedAt}' --output json`
- **Shell:** direto · **diretório:** `/mnt/c/Users/lucas/unifaat-devops-portfolio/aula-09/technova-api`
- **Início:** 2026-10-15T21:19:25-03:00 · **fim:** 2026-10-15T21:19:26-03:00 · **duração:** 1.472 s
- **Código de retorno:** 0
- `009_211925_scan-on-push-do-ecr-resultado-da-release.txt` — TXT — saída real do processo — SHA-256 `01ccd29a6a37a457ea99393d03426cdb63da8353d4a18133517f610e59aed31c`
- `009_211925_scan-on-push-do-ecr-resultado-da-release_renderizada.png` — PNG — imagem renderizada (não é captura de tela) — SHA-256 `6b517a8e25de02df209dafc3a791accd6e96807bee66565bad6ca76dc9e4381b`

### #010 — Configuracao do repositorio: scan on push e lifecycle policy

- **Comando:** `bash -c 'aws ecr describe-repositories --repository-names technova-api --region us-east-1 --query "repositories[0].{uri:repositoryUri,scanOnPush:imageScanningConfiguration.scanOnPush,mutabilidade:imageTagMutability}" --output table && aws ecr get-lifecycle-policy --repository-name technova-api --region us-east-1 --query lifecyclePolicyText --output text'`
- **Shell:** direto · **diretório:** `/mnt/c/Users/lucas/unifaat-devops-portfolio/aula-09/technova-api`
- **Início:** 2026-10-15T21:19:27-03:00 · **fim:** 2026-10-15T21:19:30-03:00 · **duração:** 2.768 s
- **Código de retorno:** 0
- `010_211927_configuracao-do-repositorio-scan-on-push.txt` — TXT — saída real do processo — SHA-256 `0a2e12aaebfa7449d5d228046081d3d2ba265d43bc7c180a32f66a61666adc93`
- `010_211927_configuracao-do-repositorio-scan-on-push_renderizada.png` — PNG — imagem renderizada (não é captura de tela) — SHA-256 `9c378cfe5395c3de2ccbc095732f7b1d9308b3a1991abdb99a4b99c2fcb69e48`

### #011 — Teste de acesso ao Amazon Bedrock no Learner Lab (Converse)

- **Comando:** `bash -c 'for m in anthropic.claude-3-haiku-20240307-v1:0 us.anthropic.claude-haiku-4-5-20251001-v1:0 amazon.nova-micro-v1:0; do echo "== $m"; aws bedrock-runtime converse --region us-east-1 --model-id "$m" --messages "[{\"role\":\"user\",\"content\":[{\"text\":\"ok\"}]}]" --inference-config "{\"maxTokens\":5}" 2>&1 | sed "s/.*operation: //"; done; true'`
- **Shell:** direto · **diretório:** `/mnt/c/Users/lucas/unifaat-devops-portfolio/aula-09/technova-api`
- **Início:** 2026-10-15T21:21:47-03:00 · **fim:** 2026-10-15T21:21:52-03:00 · **duração:** 4.382 s
- **Código de retorno:** 0
- `011_212147_teste-de-acesso-ao-amazon-bedrock-no-lea.txt` — TXT — saída real do processo — SHA-256 `04052101211b9f89b7869836fb893268ace1b81be02545cec3f8fc0bfdc0cd94`
- `011_212147_teste-de-acesso-ao-amazon-bedrock-no-lea_renderizada.png` — PNG — imagem renderizada (não é captura de tela) — SHA-256 `e4f41e7d9abc457780ebda1e508c1bb5c6a7fb8571da790f7cb48d6ac0b541fd`

### #012 — ai-review.js com Bedrock real no Lab: fallback para regras

- **Comando:** `bash -c 'BEDROCK_MODEL_ID=us.anthropic.claude-haiku-4-5-20251001-v1:0 DIFF_FILE=aula-09/exemplos/pr-inseguro.diff REVIEW_OUTPUT=/tmp/claude-1000/-mnt-c-Users-lucas-devops-20262/0a372ff8-8d7b-4bff-93e9-f177175996bc/scratchpad/ev1.md node .github/scripts/ai-review.js | grep -E '"'"'Bedrock|indisponível|Análise concluída|fallback'"'"''`
- **Shell:** direto · **diretório:** `/mnt/c/Users/lucas/unifaat-devops-portfolio`
- **Início:** 2026-10-15T21:26:31-03:00 · **fim:** 2026-10-15T21:26:33-03:00 · **duração:** 2.272 s
- **Código de retorno:** 0
- `012_212631_ai-review-js-com-bedrock-real-no-lab-fal.txt` — TXT — saída real do processo — SHA-256 `bf21c8588b1bdc26e937330b16c38ac828711ef835cd4e8776d2ed7362cf9372`
- `012_212631_ai-review-js-com-bedrock-real-no-lab-fal_renderizada.png` — PNG — imagem renderizada (não é captura de tela) — SHA-256 `7fa04ca0adb86529a2675aa395b9c27f1bbe81201c45931f0fb077980a1e8fdc`

### #013 — ai-review.js com resposta SIMULADA do Bedrock (aws falso no PATH): parse e tabela do LLM

- **Comando:** `bash -c 'PATH=/tmp/claude-1000/-mnt-c-Users-lucas-devops-20262/0a372ff8-8d7b-4bff-93e9-f177175996bc/scratchpad/fakebin:$PATH BEDROCK_MODEL_ID=modelo-simulado DIFF_FILE=aula-09/exemplos/pr-inseguro.diff REVIEW_OUTPUT=/tmp/claude-1000/-mnt-c-Users-lucas-devops-20262/0a372ff8-8d7b-4bff-93e9-f177175996bc/scratchpad/ev2.md node .github/scripts/ai-review.js >/dev/null; sed -n '"'"'/Análise do LLM/,/^---/p'"'"' /tmp/claude-1000/-mnt-c-Users-lucas-devops-20262/0a372ff8-8d7b-4bff-93e9-f177175996bc/scratchpad/ev2.md'`
- **Shell:** direto · **diretório:** `/mnt/c/Users/lucas/unifaat-devops-portfolio`
- **Início:** 2026-10-15T21:26:34-03:00 · **fim:** 2026-10-15T21:26:35-03:00 · **duração:** 0.262 s
- **Código de retorno:** 0
- `013_212634_ai-review-js-com-resposta-simulada-do-be.txt` — TXT — saída real do processo — SHA-256 `13ec18f21cee0baefcf64e8a92c266365c6c606501dc0c2e7d861001cfb2f407`
- `013_212634_ai-review-js-com-resposta-simulada-do-be_renderizada.png` — PNG — imagem renderizada (não é captura de tela) — SHA-256 `18b061289f02bc53f3bb287cfc5ecb090d3a38ce22deb7b5dc29a38d5ea62649`

## Verificação de integridade

- ✅ Todos os arquivos existem e conferem com o SHA-256 registrado.
