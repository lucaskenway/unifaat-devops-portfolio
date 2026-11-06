# Evidências — aula-11 blue-green deploy e rollback

- **Projeto:** `unifaat-devops-portfolio`
- **Início da sessão:** 2026-11-06T20:14:33-03:00
- **Fim da sessão:** 2026-11-06T20:16:25-03:00
- **Ambiente:** WSL (Ubuntu) Ubuntu 26.04 LTS · usuário `lucaskenway` · host `DESKTOP-AMJ5UEC`
- **Comandos registrados:** 3 (3 com retorno 0, 0 com falha) · **capturas de tela:** 0

> Gerado pela ferramenta `evidencia`. Os TXT contêm a saída capturada diretamente dos processos, sem edição; a única alteração possível é a troca de dados sensíveis por `[REDIGIDO:tipo]`, sempre informada abaixo. Imagens **renderizadas** são desenhadas a partir do TXT e **não são capturas de tela**; capturas **autênticas** são cópias dos pixels da tela.

## Índice

| # | Horário | Descrição | Comando | Retorno | Arquivos |
|---|---------|-----------|---------|---------|----------|
| 001 | 20:14:33 | Log real do deploy Blue/Green e do rollback automatico da aula 11 (runs 42309886648 e 42310187138) | `bash -c 'for r in 42309886648 42310187138; do echo "===== run $r ====="; gh run view $r -R lucaskenway/unifaat-devops-portfolio --log \| sed '"'"'s/^[^\t]*\t[^\t]*\t//'"'"' \| grep -vE '"'"'\[36;1m\|^ +[A-Z_]+: '"'"' \| grep -E '"'"'^20.*(🔀\|✅\|❌ requisição 1/\|ERRO\|ativo\|ocioso\|healthy\|rollback\|ROLLBACK)'"'"' \| grep -v '"'"'requisição [2-9]'"'"' \| head -25; done'` | ✅ 0 | [001_201433_log-real-do-deploy-blue-green-e-do-rollb.txt](001_201433_log-real-do-deploy-blue-green-e-do-rollb.txt) — TXT — saída real do processo<br>[001_201433_log-real-do-deploy-blue-green-e-do-rollb_renderizada.png](001_201433_log-real-do-deploy-blue-green-e-do-rollb_renderizada.png) — PNG — imagem renderizada (não é captura de tela) |
| 002 | 20:14:51 | Log real do deploy Blue/Green e do rollback automatico da aula 11 (runs 42309886648 e 42310187138) - filtro corrigido | `bash -c 'for r in 42309886648 42310187138; do echo "===== run $r ====="; gh run view $r -R lucaskenway/unifaat-devops-portfolio --log \| sed '"'"'s/^[^\t]*\t[^\t]*\t//'"'"' \| grep -E '"'"'\] '"'"' \| grep -vE '"'"'\[36;1m\|requisição ([2-9]\|1[0-9]\|20)/\|aguardando\|target group .*: (initial\|unused)'"'"' \| sed '"'"'s/^[0-9T:.-]*Z //'"'"' \| head -30; done'` | ✅ 0 | [002_201451_log-real-do-deploy-blue-green-e-do-rollb.txt](002_201451_log-real-do-deploy-blue-green-e-do-rollb.txt) — TXT — saída real do processo<br>[002_201451_log-real-do-deploy-blue-green-e-do-rollb_renderizada.png](002_201451_log-real-do-deploy-blue-green-e-do-rollb_renderizada.png) — PNG — imagem renderizada (não é captura de tela) |
| 003 | 20:15:08 | Log real do deploy Blue/Green e do rollback automatico da aula 11 (runs 42309886648 e 42310187138) - via API de jobs | `bash -c 'bash aula-11/scripts/log-run.sh 42309886648; bash aula-11/scripts/log-run.sh 42310187138'` | ✅ 0 | [003_201508_log-real-do-deploy-blue-green-e-do-rollb.txt](003_201508_log-real-do-deploy-blue-green-e-do-rollb.txt) — TXT — saída real do processo<br>[003_201508_log-real-do-deploy-blue-green-e-do-rollb_renderizada.png](003_201508_log-real-do-deploy-blue-green-e-do-rollb_renderizada.png) — PNG — imagem renderizada (não é captura de tela) |

## Detalhes

### #001 — Log real do deploy Blue/Green e do rollback automatico da aula 11 (runs 42309886648 e 42310187138)

- **Comando:** `bash -c 'for r in 42309886648 42310187138; do echo "===== run $r ====="; gh run view $r -R lucaskenway/unifaat-devops-portfolio --log | sed '"'"'s/^[^\t]*\t[^\t]*\t//'"'"' | grep -vE '"'"'\[36;1m|^ +[A-Z_]+: '"'"' | grep -E '"'"'^20.*(🔀|✅|❌ requisição 1/|ERRO|ativo|ocioso|healthy|rollback|ROLLBACK)'"'"' | grep -v '"'"'requisição [2-9]'"'"' | head -25; done'`
- **Shell:** direto · **diretório:** `/mnt/c/Users/lucas/unifaat-devops-portfolio`
- **Início:** 2026-11-06T20:14:33-03:00 · **fim:** 2026-11-06T20:14:39-03:00 · **duração:** 5.870 s
- **Código de retorno:** 0
- `001_201433_log-real-do-deploy-blue-green-e-do-rollb.txt` — TXT — saída real do processo — SHA-256 `63be5e0d6d3e4c855d88a310f04dfcb2bf953ea595bb1b5ef343401fd4b63ebf`
- `001_201433_log-real-do-deploy-blue-green-e-do-rollb_renderizada.png` — PNG — imagem renderizada (não é captura de tela) — SHA-256 `92a2da8d443a35a75ad15c6681a707906d9d43f8c5c32ee311ce6f13067c106c`

### #002 — Log real do deploy Blue/Green e do rollback automatico da aula 11 (runs 42309886648 e 42310187138) - filtro corrigido

- **Comando:** `bash -c 'for r in 42309886648 42310187138; do echo "===== run $r ====="; gh run view $r -R lucaskenway/unifaat-devops-portfolio --log | sed '"'"'s/^[^\t]*\t[^\t]*\t//'"'"' | grep -E '"'"'\] '"'"' | grep -vE '"'"'\[36;1m|requisição ([2-9]|1[0-9]|20)/|aguardando|target group .*: (initial|unused)'"'"' | sed '"'"'s/^[0-9T:.-]*Z //'"'"' | head -30; done'`
- **Shell:** direto · **diretório:** `/mnt/c/Users/lucas/unifaat-devops-portfolio`
- **Início:** 2026-11-06T20:14:51-03:00 · **fim:** 2026-11-06T20:14:54-03:00 · **duração:** 2.615 s
- **Código de retorno:** 0
- `002_201451_log-real-do-deploy-blue-green-e-do-rollb.txt` — TXT — saída real do processo — SHA-256 `9bdb9244363c853c4ee6e01423d17fe8df442e724e2c13ca789a19c54978b767`
- `002_201451_log-real-do-deploy-blue-green-e-do-rollb_renderizada.png` — PNG — imagem renderizada (não é captura de tela) — SHA-256 `4c14bc10e59ca37c3b8f8654f4000da56bcc6457d9683ac7b99e240eabb0f38e`

### #003 — Log real do deploy Blue/Green e do rollback automatico da aula 11 (runs 42309886648 e 42310187138) - via API de jobs

- **Comando:** `bash -c 'bash aula-11/scripts/log-run.sh 42309886648; bash aula-11/scripts/log-run.sh 42310187138'`
- **Shell:** direto · **diretório:** `/mnt/c/Users/lucas/unifaat-devops-portfolio`
- **Início:** 2026-11-06T20:15:08-03:00 · **fim:** 2026-11-06T20:15:14-03:00 · **duração:** 6.257 s
- **Código de retorno:** 0
- `003_201508_log-real-do-deploy-blue-green-e-do-rollb.txt` — TXT — saída real do processo — SHA-256 `2a0b9b7790777b24a7d033c1c8ebad3b1180d7489e50b34044a3a864c85b1cd2`
- `003_201508_log-real-do-deploy-blue-green-e-do-rollb_renderizada.png` — PNG — imagem renderizada (não é captura de tela) — SHA-256 `9eda76dda7107ddee16cc2e09b0c7f41099551838df78cc5cfbda3e091e3886e`

## Verificação de integridade

- ✅ Todos os arquivos existem e conferem com o SHA-256 registrado.
