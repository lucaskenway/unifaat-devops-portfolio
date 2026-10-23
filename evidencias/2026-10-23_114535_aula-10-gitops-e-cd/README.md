# Evidências — aula-10 GitOps e CD

- **Projeto:** `unifaat-devops-portfolio`
- **Início da sessão:** 2026-10-23T11:45:35-03:00
- **Fim da sessão:** 2026-10-23T11:53:59-03:00
- **Ambiente:** WSL (Ubuntu) Ubuntu 26.04 LTS · usuário `lucaskenway` · host `DESKTOP-AMJ5UEC`
- **Comandos registrados:** 10 (9 com retorno 0, 1 com falha) · **capturas de tela:** 0

> Gerado pela ferramenta `evidencia`. Os TXT contêm a saída capturada diretamente dos processos, sem edição; a única alteração possível é a troca de dados sensíveis por `[REDIGIDO:tipo]`, sempre informada abaixo. Imagens **renderizadas** são desenhadas a partir do TXT e **não são capturas de tela**; capturas **autênticas** são cópias dos pixels da tela.

## Índice

| # | Horário | Descrição | Comando | Retorno | Arquivos |
|---|---------|-----------|---------|---------|----------|
| 001 | 11:45:35 | Log do Terraform Apply (run 39970717413) apos o merge do PR #5 | `bash -c 'gh run view 39970717413 --log \| awk -F'"'"'\t'"'"' '"'"'$2=="Terraform Apply" \|\| $2=="Outputs"'"'"' \| sed -E '"'"'s/^[^\t]*\t//; s/\t[0-9TZ:.-]+ /  /'"'"' \| grep -E '"'"'Creation complete\|Apply complete\|= "'"'"' \| grep -vE '"'"'\[36;1m\|\+ "'"'"' \| head -30'` | ✅ 0 | [001_114535_log-do-terraform-apply-run-39970717413-a.txt](001_114535_log-do-terraform-apply-run-39970717413-a.txt) — TXT — saída real do processo<br>[001_114535_log-do-terraform-apply-run-39970717413-a_renderizada.png](001_114535_log-do-terraform-apply-run-39970717413-a_renderizada.png) — PNG — imagem renderizada (não é captura de tela) |
| 002 | 11:45:37 | Health check e conferencia de /version no job deploy (run 39971130945) | `bash -c 'gh run view 39971130945 --log \| awk -F'"'"'\t'"'"' '"'"'$2=="Health Check" \|\| $2=="Conferir versão implantada" \|\| $2=="Deploy via SSH (Recreate Strategy)"'"'"' \| sed -E '"'"'s/^[^\t]*\t//; s/\t[0-9TZ:.-]+ /  /'"'"' \| grep -vE '"'"'\[36;1m\|##\[\|DeprecationWarning\|url.parse\|WARN'"'"' \| grep -E '"'"'🔐\|🛑\|📦\|▶️\|✅\|⏳\|❌\|status\|version\|Login Succeeded\|technova-api\|Status:'"'"' \| head -40'` | ✅ 0 | [002_114537_health-check-e-conferencia-de-version-no.txt](002_114537_health-check-e-conferencia-de-version-no.txt) — TXT — saída real do processo<br>[002_114537_health-check-e-conferencia-de-version-no_renderizada.png](002_114537_health-check-e-conferencia-de-version-no_renderizada.png) — PNG — imagem renderizada (não é captura de tela) |
| 003 | 11:45:39 | Acesso externo a API implantada na EC2 | `bash -c 'curl -s http://100.57.3.69:3000/health; echo; curl -s http://100.57.3.69:3000/version; echo'` | ✅ 0 | [003_114539_acesso-externo-a-api-implantada-na-ec2.txt](003_114539_acesso-externo-a-api-implantada-na-ec2.txt) — TXT — saída real do processo<br>[003_114539_acesso-externo-a-api-implantada-na-ec2_renderizada.png](003_114539_acesso-externo-a-api-implantada-na-ec2_renderizada.png) — PNG — imagem renderizada (não é captura de tela) |
| 004 | 11:45:59 | Terraform Apply apos merge do PR #5: recursos criados e outputs (run 39970717413) | `bash -c 'gh run view 39970717413 --log \| awk -F'"'"'\t'"'"' '"'"'$2=="Terraform Apply" \|\| $2=="Outputs"'"'"' \| sed -E '"'"'s/^[^\t]*\t//; s/\t[0-9TZ:.-]+ /  /'"'"' \| grep -E '"'"'^[^\t]+  [^ ]'"'"' \| grep -E '"'"'Creation complete\|Apply complete\|^Outputs  [a-z_]+ = '"'"' \| sort -u -t'"'"'\|'"'"' -k1,1 \| head -30'` | ✅ 0 | [004_114559_terraform-apply-apos-merge-do-pr-5-recur.txt](004_114559_terraform-apply-apos-merge-do-pr-5-recur.txt) — TXT — saída real do processo<br>[004_114559_terraform-apply-apos-merge-do-pr-5-recur_renderizada.png](004_114559_terraform-apply-apos-merge-do-pr-5-recur_renderizada.png) — PNG — imagem renderizada (não é captura de tela) |
| 005 | 11:46:02 | Deploy Recreate via SSH + health check + /version (run 39971130945) | `bash -c 'gh run view 39971130945 --log \| awk -F'"'"'\t'"'"' '"'"'$2=="Deploy via SSH (Recreate Strategy)" \|\| $2=="Health Check" \|\| $2=="Conferir versão implantada"'"'"' \| sed -E '"'"'s/^[^\t]*\t//; s/\t[0-9TZ:.-]+ /  /'"'"' \| grep -E '"'"'^[^\t]+  [^ ]'"'"' \| grep -vE '"'"'Drone SSH\|Successfully executed\|^[^ ]+( [^ ]+)*  [a-f0-9]{12}: \|Digest:\|Pulling fs\|Download\|Verifying\|Pull complete\|Waiting'"'"''` | ❌ 1 | [005_114602_deploy-recreate-via-ssh-health-check-ver.txt](005_114602_deploy-recreate-via-ssh-health-check-ver.txt) — TXT — saída real do processo<br>[005_114602_deploy-recreate-via-ssh-health-check-ver_renderizada.png](005_114602_deploy-recreate-via-ssh-health-check-ver_renderizada.png) — PNG — imagem renderizada (não é captura de tela) |
| 006 | 11:46:15 | Deploy Recreate via SSH + health check + /version (run 39971130945) | `bash -c 'gh run view 39971130945 --log \| awk -F'"'"'\t'"'"' '"'"'$2=="Deploy via SSH (Recreate Strategy)" \|\| $2=="Health Check" \|\| $2=="Conferir versão implantada"'"'"' \| sed -E '"'"'s/^[^\t]*\t//; s/\t[0-9TZ:.-]+ /  /'"'"' \| grep -E '"'"'\)  [^ ]\|Check  [^ ]\|implantada  [^ ]'"'"' \| grep -vE '"'"'Drone SSH\|Successfully executed\|  [a-f0-9]{12}: \|Digest:\|Pull complete\|Waiting\|Verifying\|Download complete'"'"''` | ✅ 0 | [006_114615_deploy-recreate-via-ssh-health-check-ver.txt](006_114615_deploy-recreate-via-ssh-health-check-ver.txt) — TXT — saída real do processo<br>[006_114615_deploy-recreate-via-ssh-health-check-ver_renderizada.png](006_114615_deploy-recreate-via-ssh-health-check-ver_renderizada.png) — PNG — imagem renderizada (não é captura de tela) |
| 007 | 11:46:32 | Health check pos-deploy passando e /version com o commit implantado (run 39971130945) | `bash -c 'gh run view 39971130945 --log \| awk -F'"'"'\t'"'"' '"'"'$2=="Health Check" \|\| $2=="Conferir versão implantada"'"'"' \| sed -E '"'"'s/^[^\t]*\t//; s/\t[0-9TZ:.-]+ /  /'"'"' \| grep -E '"'"'Aguardando aplicação\|Tentativa [0-9]\|Health check passed\|falhou após\|"status":"ok"\|"commit":"[0-9a-f]{40}'"'"' \| grep -vE '"'"'echo\|grep'"'"''` | ✅ 0 | [007_114632_health-check-pos-deploy-passando-e-versi.txt](007_114632_health-check-pos-deploy-passando-e-versi.txt) — TXT — saída real do processo<br>[007_114632_health-check-pos-deploy-passando-e-versi_renderizada.png](007_114632_health-check-pos-deploy-passando-e-versi_renderizada.png) — PNG — imagem renderizada (não é captura de tela) |
| 008 | 11:51:01 | Teste do runbook de rollback: versao atual -> sha-abd19a4 (login ECR antes do pull) | `bash -c 'echo '"'"'== antes:'"'"'; curl -s http://100.57.3.69:3000/version; echo; echo '"'"'== rollback na EC2 (via SSH):'"'"'; ssh -o StrictHostKeyChecking=accept-new -i ~/.ssh/technova-aula10-deploy.pem ec2-user@100.57.3.69 '"'"'bash -s sha-abd19a4'"'"' < /home/lucaskenway/.claude-tmp/claude-1000/-mnt-c-Users-lucas-devops-20262/34f3b92f-18e7-4df7-bb12-7fe0d540429c/scratchpad/rollback.sh; echo '"'"'== depois (acesso externo):'"'"'; curl -s http://100.57.3.69:3000/version; echo'` | ✅ 0 | [008_115101_teste-do-runbook-de-rollback-versao-atua.txt](008_115101_teste-do-runbook-de-rollback-versao-atua.txt) — TXT — saída real do processo<br>[008_115101_teste-do-runbook-de-rollback-versao-atua_renderizada.png](008_115101_teste-do-runbook-de-rollback-versao-atua_renderizada.png) — PNG — imagem renderizada (não é captura de tela) |
| 009 | 11:53:33 | Retorno a versao da main apos o teste de rollback (cd.yml via workflow_dispatch, run 39973365347) | `bash -c 'curl -s http://100.57.3.69:3000/version; echo; git log -1 --format='"'"'main = %H'"'"' origin/main'` | ✅ 0 | [009_115333_retorno-a-versao-da-main-apos-o-teste-de.txt](009_115333_retorno-a-versao-da-main-apos-o-teste-de.txt) — TXT — saída real do processo<br>[009_115333_retorno-a-versao-da-main-apos-o-teste-de_renderizada.png](009_115333_retorno-a-versao-da-main-apos-o-teste-de_renderizada.png) — PNG — imagem renderizada (não é captura de tela) |
| 010 | 11:53:55 | Versao no ar = HEAD da main remota (corrige o #009, que usou origin/main local desatualizado) | `bash -c 'git fetch -q origin; git log -1 --format='"'"'main = %H'"'"' origin/main; curl -s http://100.57.3.69:3000/version; echo'` | ✅ 0 | [010_115355_versao-no-ar-head-da-main-remota-corrige.txt](010_115355_versao-no-ar-head-da-main-remota-corrige.txt) — TXT — saída real do processo<br>[010_115355_versao-no-ar-head-da-main-remota-corrige_renderizada.png](010_115355_versao-no-ar-head-da-main-remota-corrige_renderizada.png) — PNG — imagem renderizada (não é captura de tela) |

## Detalhes

### #001 — Log do Terraform Apply (run 39970717413) apos o merge do PR #5

- **Comando:** `bash -c 'gh run view 39970717413 --log | awk -F'"'"'\t'"'"' '"'"'$2=="Terraform Apply" || $2=="Outputs"'"'"' | sed -E '"'"'s/^[^\t]*\t//; s/\t[0-9TZ:.-]+ /  /'"'"' | grep -E '"'"'Creation complete|Apply complete|= "'"'"' | grep -vE '"'"'\[36;1m|\+ "'"'"' | head -30'`
- **Shell:** direto · **diretório:** `/mnt/c/Users/lucas/unifaat-devops-portfolio`
- **Início:** 2026-10-23T11:45:35-03:00 · **fim:** 2026-10-23T11:45:36-03:00 · **duração:** 1.432 s
- **Código de retorno:** 0
- `001_114535_log-do-terraform-apply-run-39970717413-a.txt` — TXT — saída real do processo — SHA-256 `827faa6c3cdd993a7b5b98a5b997aa04d8c54dc6f5dd5477420d272bf1c19735`
- `001_114535_log-do-terraform-apply-run-39970717413-a_renderizada.png` — PNG — imagem renderizada (não é captura de tela) — SHA-256 `ac0b550634b6bba62f90065018c324137adf7b5bf2967a194af6ba1bac55d3b6`

### #002 — Health check e conferencia de /version no job deploy (run 39971130945)

- **Comando:** `bash -c 'gh run view 39971130945 --log | awk -F'"'"'\t'"'"' '"'"'$2=="Health Check" || $2=="Conferir versão implantada" || $2=="Deploy via SSH (Recreate Strategy)"'"'"' | sed -E '"'"'s/^[^\t]*\t//; s/\t[0-9TZ:.-]+ /  /'"'"' | grep -vE '"'"'\[36;1m|##\[|DeprecationWarning|url.parse|WARN'"'"' | grep -E '"'"'🔐|🛑|📦|▶️|✅|⏳|❌|status|version|Login Succeeded|technova-api|Status:'"'"' | head -40'`
- **Shell:** direto · **diretório:** `/mnt/c/Users/lucas/unifaat-devops-portfolio`
- **Início:** 2026-10-23T11:45:37-03:00 · **fim:** 2026-10-23T11:45:38-03:00 · **duração:** 1.344 s
- **Código de retorno:** 0
- `002_114537_health-check-e-conferencia-de-version-no.txt` — TXT — saída real do processo — SHA-256 `ad3bc179f6813315d977488247497ec0347063702b7c06cd689f99fbf87ea92b`
- `002_114537_health-check-e-conferencia-de-version-no_renderizada.png` — PNG — imagem renderizada (não é captura de tela) — SHA-256 `6f41a4675f35032bc910cee8dcc4e976d71c380975c51d03ae10ee548c16ee43`

### #003 — Acesso externo a API implantada na EC2

- **Comando:** `bash -c 'curl -s http://100.57.3.69:3000/health; echo; curl -s http://100.57.3.69:3000/version; echo'`
- **Shell:** direto · **diretório:** `/mnt/c/Users/lucas/unifaat-devops-portfolio`
- **Início:** 2026-10-23T11:45:39-03:00 · **fim:** 2026-10-23T11:45:40-03:00 · **duração:** 0.762 s
- **Código de retorno:** 0
- `003_114539_acesso-externo-a-api-implantada-na-ec2.txt` — TXT — saída real do processo — SHA-256 `061af51a655a70e9c78992dde74ea83499c8d9782b6ffab4a7a0a3184d8c0d04`
- `003_114539_acesso-externo-a-api-implantada-na-ec2_renderizada.png` — PNG — imagem renderizada (não é captura de tela) — SHA-256 `6ab868f4ee1d9e4511f0058e5aad902a28b01f6740c5c589b51b0581b8b845a3`

### #004 — Terraform Apply apos merge do PR #5: recursos criados e outputs (run 39970717413)

- **Comando:** `bash -c 'gh run view 39970717413 --log | awk -F'"'"'\t'"'"' '"'"'$2=="Terraform Apply" || $2=="Outputs"'"'"' | sed -E '"'"'s/^[^\t]*\t//; s/\t[0-9TZ:.-]+ /  /'"'"' | grep -E '"'"'^[^\t]+  [^ ]'"'"' | grep -E '"'"'Creation complete|Apply complete|^Outputs  [a-z_]+ = '"'"' | sort -u -t'"'"'|'"'"' -k1,1 | head -30'`
- **Shell:** direto · **diretório:** `/mnt/c/Users/lucas/unifaat-devops-portfolio`
- **Início:** 2026-10-23T11:45:59-03:00 · **fim:** 2026-10-23T11:46:01-03:00 · **duração:** 1.766 s
- **Código de retorno:** 0
- `004_114559_terraform-apply-apos-merge-do-pr-5-recur.txt` — TXT — saída real do processo — SHA-256 `f0fa80c06a3669d5b69bfe980724955a767df0090f8d31fc8815504684b47135`
- `004_114559_terraform-apply-apos-merge-do-pr-5-recur_renderizada.png` — PNG — imagem renderizada (não é captura de tela) — SHA-256 `39ff6342fc2740893eebf430b1ea2b96ff3ed48f8b648ced398ad33e9f09451d`

### #005 — Deploy Recreate via SSH + health check + /version (run 39971130945)

- **Comando:** `bash -c 'gh run view 39971130945 --log | awk -F'"'"'\t'"'"' '"'"'$2=="Deploy via SSH (Recreate Strategy)" || $2=="Health Check" || $2=="Conferir versão implantada"'"'"' | sed -E '"'"'s/^[^\t]*\t//; s/\t[0-9TZ:.-]+ /  /'"'"' | grep -E '"'"'^[^\t]+  [^ ]'"'"' | grep -vE '"'"'Drone SSH|Successfully executed|^[^ ]+( [^ ]+)*  [a-f0-9]{12}: |Digest:|Pulling fs|Download|Verifying|Pull complete|Waiting'"'"''`
- **Shell:** direto · **diretório:** `/mnt/c/Users/lucas/unifaat-devops-portfolio`
- **Início:** 2026-10-23T11:46:02-03:00 · **fim:** 2026-10-23T11:46:03-03:00 · **duração:** 1.354 s
- **Código de retorno:** 1
- `005_114602_deploy-recreate-via-ssh-health-check-ver.txt` — TXT — saída real do processo — SHA-256 `e017fc819a461a4b2295a047df6380ac16268ac1d8f690f6c13741addbd691f4`
- `005_114602_deploy-recreate-via-ssh-health-check-ver_renderizada.png` — PNG — imagem renderizada (não é captura de tela) — SHA-256 `0e28bbcb08d1a04012f063babb105d392a35dec38c749c78f88b21f2ae433bf9`

### #006 — Deploy Recreate via SSH + health check + /version (run 39971130945)

- **Comando:** `bash -c 'gh run view 39971130945 --log | awk -F'"'"'\t'"'"' '"'"'$2=="Deploy via SSH (Recreate Strategy)" || $2=="Health Check" || $2=="Conferir versão implantada"'"'"' | sed -E '"'"'s/^[^\t]*\t//; s/\t[0-9TZ:.-]+ /  /'"'"' | grep -E '"'"'\)  [^ ]|Check  [^ ]|implantada  [^ ]'"'"' | grep -vE '"'"'Drone SSH|Successfully executed|  [a-f0-9]{12}: |Digest:|Pull complete|Waiting|Verifying|Download complete'"'"''`
- **Shell:** direto · **diretório:** `/mnt/c/Users/lucas/unifaat-devops-portfolio`
- **Início:** 2026-10-23T11:46:15-03:00 · **fim:** 2026-10-23T11:46:16-03:00 · **duração:** 1.409 s
- **Código de retorno:** 0
- `006_114615_deploy-recreate-via-ssh-health-check-ver.txt` — TXT — saída real do processo — SHA-256 `88b4d4cd6eb45c1bef238f18ffb7d4143a693c50f7170fd18c801f10bf87c3df`
- `006_114615_deploy-recreate-via-ssh-health-check-ver_renderizada.png` — PNG — imagem renderizada (não é captura de tela) — SHA-256 `5d9a29d75ae2c4d2be5a9985480c54e7340fd90398fe1346538e630c8966bb32`

### #007 — Health check pos-deploy passando e /version com o commit implantado (run 39971130945)

- **Comando:** `bash -c 'gh run view 39971130945 --log | awk -F'"'"'\t'"'"' '"'"'$2=="Health Check" || $2=="Conferir versão implantada"'"'"' | sed -E '"'"'s/^[^\t]*\t//; s/\t[0-9TZ:.-]+ /  /'"'"' | grep -E '"'"'Aguardando aplicação|Tentativa [0-9]|Health check passed|falhou após|"status":"ok"|"commit":"[0-9a-f]{40}'"'"' | grep -vE '"'"'echo|grep'"'"''`
- **Shell:** direto · **diretório:** `/mnt/c/Users/lucas/unifaat-devops-portfolio`
- **Início:** 2026-10-23T11:46:32-03:00 · **fim:** 2026-10-23T11:46:33-03:00 · **duração:** 1.453 s
- **Código de retorno:** 0
- `007_114632_health-check-pos-deploy-passando-e-versi.txt` — TXT — saída real do processo — SHA-256 `432ddb490ad0952c05e58dd810c0dab773a82aabe35d4fa19a4a7ceb1a9fc169`
- `007_114632_health-check-pos-deploy-passando-e-versi_renderizada.png` — PNG — imagem renderizada (não é captura de tela) — SHA-256 `ae2d6d4e4298700e6ef845fd1f984e98c899f3612d51df63fd7b94a5a372ba2d`

### #008 — Teste do runbook de rollback: versao atual -> sha-abd19a4 (login ECR antes do pull)

- **Comando:** `bash -c 'echo '"'"'== antes:'"'"'; curl -s http://100.57.3.69:3000/version; echo; echo '"'"'== rollback na EC2 (via SSH):'"'"'; ssh -o StrictHostKeyChecking=accept-new -i ~/.ssh/technova-aula10-deploy.pem ec2-user@100.57.3.69 '"'"'bash -s sha-abd19a4'"'"' < /home/lucaskenway/.claude-tmp/claude-1000/-mnt-c-Users-lucas-devops-20262/34f3b92f-18e7-4df7-bb12-7fe0d540429c/scratchpad/rollback.sh; echo '"'"'== depois (acesso externo):'"'"'; curl -s http://100.57.3.69:3000/version; echo'`
- **Shell:** direto · **diretório:** `/mnt/c/Users/lucas/unifaat-devops-portfolio`
- **Início:** 2026-10-23T11:51:01-03:00 · **fim:** 2026-10-23T11:51:20-03:00 · **duração:** 18.325 s
- **Código de retorno:** 0
- `008_115101_teste-do-runbook-de-rollback-versao-atua.txt` — TXT — saída real do processo — SHA-256 `f3bc5dc5467f8c3502c09716bde922efbf495835bb41b25325f0cb6835f5babe`
- `008_115101_teste-do-runbook-de-rollback-versao-atua_renderizada.png` — PNG — imagem renderizada (não é captura de tela) — SHA-256 `405047361e18ebea5edf390e10a4cc5cc90c37281b20449d97cbd5106a2df5e1`

### #009 — Retorno a versao da main apos o teste de rollback (cd.yml via workflow_dispatch, run 39973365347)

- **Comando:** `bash -c 'curl -s http://100.57.3.69:3000/version; echo; git log -1 --format='"'"'main = %H'"'"' origin/main'`
- **Shell:** direto · **diretório:** `/mnt/c/Users/lucas/unifaat-devops-portfolio`
- **Início:** 2026-10-23T11:53:33-03:00 · **fim:** 2026-10-23T11:53:34-03:00 · **duração:** 0.671 s
- **Código de retorno:** 0
- `009_115333_retorno-a-versao-da-main-apos-o-teste-de.txt` — TXT — saída real do processo — SHA-256 `d08ad34147cd246340399e921fc56ee74461db5ff86a76de99e0e21ccc453ccd`
- `009_115333_retorno-a-versao-da-main-apos-o-teste-de_renderizada.png` — PNG — imagem renderizada (não é captura de tela) — SHA-256 `097276afad462f8aa7a40f153f95b5d2b4659c76045bedc9ddfae0a8aa4d3678`

### #010 — Versao no ar = HEAD da main remota (corrige o #009, que usou origin/main local desatualizado)

- **Comando:** `bash -c 'git fetch -q origin; git log -1 --format='"'"'main = %H'"'"' origin/main; curl -s http://100.57.3.69:3000/version; echo'`
- **Shell:** direto · **diretório:** `/mnt/c/Users/lucas/unifaat-devops-portfolio`
- **Início:** 2026-10-23T11:53:55-03:00 · **fim:** 2026-10-23T11:53:58-03:00 · **duração:** 3.495 s
- **Código de retorno:** 0
- `010_115355_versao-no-ar-head-da-main-remota-corrige.txt` — TXT — saída real do processo — SHA-256 `f991950b0d209c9af334c869bf9decec22135f10f5cf2252d0121720681fd439`
- `010_115355_versao-no-ar-head-da-main-remota-corrige_renderizada.png` — PNG — imagem renderizada (não é captura de tela) — SHA-256 `25d35f2748de3c0373c98c1ab5fcf11827f3bbb6aa949435269efadc2564ad04`

## Verificação de integridade

- ✅ Todos os arquivos existem e conferem com o SHA-256 registrado.
