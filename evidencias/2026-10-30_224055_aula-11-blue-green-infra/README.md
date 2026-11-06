# Evidências — aula-11 blue-green infra

- **Projeto:** `unifaat-devops-portfolio`
- **Início da sessão:** 2026-10-30T22:40:55-03:00
- **Fim da sessão:** 2026-10-30T22:51:29-03:00
- **Ambiente:** WSL (Ubuntu) Ubuntu 26.04 LTS · usuário `lucaskenway` · host `DESKTOP-AMJ5UEC`
- **Comandos registrados:** 4 (4 com retorno 0, 0 com falha) · **capturas de tela:** 0

> Gerado pela ferramenta `evidencia`. Os TXT contêm a saída capturada diretamente dos processos, sem edição; a única alteração possível é a troca de dados sensíveis por `[REDIGIDO:tipo]`, sempre informada abaixo. Imagens **renderizadas** são desenhadas a partir do TXT e **não são capturas de tela**; capturas **autênticas** são cópias dos pixels da tela.

## Índice

| # | Horário | Descrição | Comando | Retorno | Arquivos |
|---|---------|-----------|---------|---------|----------|
| 001 | 22:40:55 | terraform validate | `terraform validate` | ✅ 0 | [001_224055_terraform-validate.txt](001_224055_terraform-validate.txt) — TXT — saída real do processo<br>[001_224055_terraform-validate_renderizada.png](001_224055_terraform-validate_renderizada.png) — PNG — imagem renderizada (não é captura de tela) |
| 002 | 22:41:29 | outputs do terraform (ALB, listener, target groups) | `terraform output` | ✅ 0 | [002_224129_outputs-do-terraform-alb-listener-target.txt](002_224129_outputs-do-terraform-alb-listener-target.txt) — TXT — saída real do processo<br>[002_224129_outputs-do-terraform-alb-listener-target_renderizada.png](002_224129_outputs-do-terraform-alb-listener-target_renderizada.png) — PNG — imagem renderizada (não é captura de tela) |
| 003 | 22:41:49 | estado blue/green antes do primeiro deploy | `bash aula-11/scripts/bluegreen.sh status` | ✅ 0 | [003_224149_estado-blue-green-antes-do-primeiro-depl.txt](003_224149_estado-blue-green-antes-do-primeiro-depl.txt) — TXT — saída real do processo<br>[003_224149_estado-blue-green-antes-do-primeiro-depl_renderizada.png](003_224149_estado-blue-green-antes-do-primeiro-depl_renderizada.png) — PNG — imagem renderizada (não é captura de tela) |
| 004 | 22:42:13 | ALB antes do deploy (502: nenhum target healthy) | `curl -s -i http://6325226-a11-alb-952867794.us-east-1.elb.amazonaws.com/health` | ✅ 0 | [004_224213_alb-antes-do-deploy-502-nenhum-target-he.txt](004_224213_alb-antes-do-deploy-502-nenhum-target-he.txt) — TXT — saída real do processo<br>[004_224213_alb-antes-do-deploy-502-nenhum-target-he_renderizada.png](004_224213_alb-antes-do-deploy-502-nenhum-target-he_renderizada.png) — PNG — imagem renderizada (não é captura de tela) |

## Detalhes

### #001 — terraform validate

- **Comando:** `terraform validate`
- **Shell:** direto · **diretório:** `/mnt/c/Users/lucas/unifaat-devops-portfolio/aula-11/terraform`
- **Início:** 2026-10-30T22:40:55-03:00 · **fim:** 2026-10-30T22:41:28-03:00 · **duração:** 32.308 s
- **Código de retorno:** 0
- `001_224055_terraform-validate.txt` — TXT — saída real do processo — SHA-256 `898f5fd9f93a6e1a2a3a0f36e65d321cfb6caecbf56fa328956a48c1a7c1c8a6`
- `001_224055_terraform-validate_renderizada.png` — PNG — imagem renderizada (não é captura de tela) — SHA-256 `cb8826a8099fb38ea6be54c508899544e204a22d07cfa17d56718390febb11fc`

### #002 — outputs do terraform (ALB, listener, target groups)

- **Comando:** `terraform output`
- **Shell:** direto · **diretório:** `/mnt/c/Users/lucas/unifaat-devops-portfolio/aula-11/terraform`
- **Início:** 2026-10-30T22:41:29-03:00 · **fim:** 2026-10-30T22:41:49-03:00 · **duração:** 20.187 s
- **Código de retorno:** 0
- `002_224129_outputs-do-terraform-alb-listener-target.txt` — TXT — saída real do processo — SHA-256 `4f4da06f853570014e29ddbb27cd61b25212a0de9968eda95d24abcec2e38f17`
- `002_224129_outputs-do-terraform-alb-listener-target_renderizada.png` — PNG — imagem renderizada (não é captura de tela) — SHA-256 `1f4f382ceda3792495c8d7138f5d768ce94bfd68bcfd68cde1eda24e16c20e64`

### #003 — estado blue/green antes do primeiro deploy

- **Comando:** `bash aula-11/scripts/bluegreen.sh status`
- **Shell:** direto · **diretório:** `/mnt/c/Users/lucas/unifaat-devops-portfolio`
- **Início:** 2026-10-30T22:41:49-03:00 · **fim:** 2026-10-30T22:42:12-03:00 · **duração:** 22.933 s
- **Código de retorno:** 0
- `003_224149_estado-blue-green-antes-do-primeiro-depl.txt` — TXT — saída real do processo — SHA-256 `a2f663a17fc7f521adb434c6fda1d7555f67c7b979fe7a22961b37e7de3adc20`
- `003_224149_estado-blue-green-antes-do-primeiro-depl_renderizada.png` — PNG — imagem renderizada (não é captura de tela) — SHA-256 `18ac1efa59f93d8114122fb16ef5ec6b26bc6716b4de23cb25e34373afb8f3b7`

### #004 — ALB antes do deploy (502: nenhum target healthy)

- **Comando:** `curl -s -i http://6325226-a11-alb-952867794.us-east-1.elb.amazonaws.com/health`
- **Shell:** direto · **diretório:** `/mnt/c/Users/lucas/unifaat-devops-portfolio`
- **Início:** 2026-10-30T22:42:13-03:00 · **fim:** 2026-10-30T22:42:14-03:00 · **duração:** 0.322 s
- **Código de retorno:** 0
- `004_224213_alb-antes-do-deploy-502-nenhum-target-he.txt` — TXT — saída real do processo — SHA-256 `2b2d1c10a3fbd3263bd5d71504820675a66a7be44996202ea25beefd80e23e9e`
- `004_224213_alb-antes-do-deploy-502-nenhum-target-he_renderizada.png` — PNG — imagem renderizada (não é captura de tela) — SHA-256 `bcd1f265dc3601e0497971410682647740d5f5b34707017f63402a1858916ff5`

## Verificação de integridade

- ✅ Todos os arquivos existem e conferem com o SHA-256 registrado.
