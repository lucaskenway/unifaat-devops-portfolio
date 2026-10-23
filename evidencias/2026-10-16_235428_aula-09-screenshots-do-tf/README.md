# Evidências — aula-09 screenshots do TF

- **Projeto:** `unifaat-devops-portfolio`
- **Início da sessão:** 2026-10-16T23:54:28-03:00
- **Fim da sessão:** 2026-10-23T12:17:22-03:00
- **Ambiente:** WSL (Ubuntu) Ubuntu 26.04 LTS · usuário `lucaskenway` · host `DESKTOP-AMJ5UEC`
- **Comandos registrados:** 3 (3 com retorno 0, 0 com falha) · **capturas de tela:** 0

> Gerado pela ferramenta `evidencia`. Os TXT contêm a saída capturada diretamente dos processos, sem edição; a única alteração possível é a troca de dados sensíveis por `[REDIGIDO:tipo]`, sempre informada abaixo. Imagens **renderizadas** são desenhadas a partir do TXT e **não são capturas de tela**; capturas **autênticas** são cópias dos pixels da tela.

## Índice

| # | Horário | Descrição | Comando | Retorno | Arquivos |
|---|---------|-----------|---------|---------|----------|
| 001 | 23:54:28 | ecr-push.sh concluido (trecho final do log 002 de 2026-10-15) | `bash -c 'sed -n '"'"'/^Comando:/,/^Código de retorno:/p'"'"' evidencias/2026-10-15_211523_aula-09-ecr-push-semver-rollback/002_211708_ecr-push-sh-com-git-tag-v1-0-0-publica-1.txt; echo '"'"'[...]'"'"'; sed -n '"'"'/==> Tags publicadas no ECR/,/:1$/p'"'"' evidencias/2026-10-15_211523_aula-09-ecr-push-semver-rollback/002_211708_ecr-push-sh-com-git-tag-v1-0-0-publica-1.txt'` | ✅ 0 | [001_235428_ecr-push-sh-concluido-trecho-final-do-lo.txt](001_235428_ecr-push-sh-concluido-trecho-final-do-lo.txt) — TXT — saída real do processo<br>[001_235428_ecr-push-sh-concluido-trecho-final-do-lo_renderizada.png](001_235428_ecr-push-sh-concluido-trecho-final-do-lo_renderizada.png) — PNG — imagem renderizada (não é captura de tela) |
| 002 | 12:17:04 | Repositorio ECR technova-api: imagens e tags publicadas pelos pipelines (conta 721003528272, us-east-1) | `bash -c 'aws ecr describe-repositories --repository-names technova-api --query '"'"'repositories[0].[repositoryUri,imageScanningConfiguration.scanOnPush]'"'"' --output text; aws ecr describe-images --repository-name technova-api --query '"'"'sort_by(imageDetails,&imagePushedAt)[].[imagePushedAt,join(`, `,imageTags\|\|[`<untagged>`]),imageDigest]'"'"' --output table'` | ✅ 0 | [002_121704_repositorio-ecr-technova-api-imagens-e-t.txt](002_121704_repositorio-ecr-technova-api-imagens-e-t.txt) — TXT — saída real do processo<br>[002_121704_repositorio-ecr-technova-api-imagens-e-t_renderizada.png](002_121704_repositorio-ecr-technova-api-imagens-e-t_renderizada.png) — PNG — imagem renderizada (não é captura de tela) |
| 003 | 12:17:18 | ECR technova-api: imagens com tag (sha-XXXXXXX por commit + latest), scan on push ativo | `bash -c 'aws ecr describe-repositories --repository-names technova-api --query '"'"'repositories[0].[repositoryUri,imageScanningConfiguration.scanOnPush]'"'"' --output text; aws ecr describe-images --repository-name technova-api --filter tagStatus=TAGGED --query '"'"'sort_by(imageDetails,&imagePushedAt)[].[imagePushedAt,join(`,`,imageTags),imageSizeInBytes]'"'"' --output table'` | ✅ 0 | [003_121718_ecr-technova-api-imagens-com-tag-sha-xxx.txt](003_121718_ecr-technova-api-imagens-com-tag-sha-xxx.txt) — TXT — saída real do processo<br>[003_121718_ecr-technova-api-imagens-com-tag-sha-xxx_renderizada.png](003_121718_ecr-technova-api-imagens-com-tag-sha-xxx_renderizada.png) — PNG — imagem renderizada (não é captura de tela) |

## Detalhes

### #001 — ecr-push.sh concluido (trecho final do log 002 de 2026-10-15)

- **Comando:** `bash -c 'sed -n '"'"'/^Comando:/,/^Código de retorno:/p'"'"' evidencias/2026-10-15_211523_aula-09-ecr-push-semver-rollback/002_211708_ecr-push-sh-com-git-tag-v1-0-0-publica-1.txt; echo '"'"'[...]'"'"'; sed -n '"'"'/==> Tags publicadas no ECR/,/:1$/p'"'"' evidencias/2026-10-15_211523_aula-09-ecr-push-semver-rollback/002_211708_ecr-push-sh-com-git-tag-v1-0-0-publica-1.txt'`
- **Shell:** direto · **diretório:** `/mnt/c/Users/lucas/unifaat-devops-portfolio`
- **Início:** 2026-10-16T23:54:28-03:00 · **fim:** 2026-10-16T23:54:28-03:00 · **duração:** 0.036 s
- **Código de retorno:** 0
- `001_235428_ecr-push-sh-concluido-trecho-final-do-lo.txt` — TXT — saída real do processo — SHA-256 `ead9b0e41931e2ed0b7cf7f59c248a89a0774e8742a3111ce1a9d4f2574c2d63`
- `001_235428_ecr-push-sh-concluido-trecho-final-do-lo_renderizada.png` — PNG — imagem renderizada (não é captura de tela) — SHA-256 `e0f2846331785125f4c3144beed3d629187f7cc878c67367d78a8814adf38bde`

### #002 — Repositorio ECR technova-api: imagens e tags publicadas pelos pipelines (conta 721003528272, us-east-1)

- **Comando:** `bash -c 'aws ecr describe-repositories --repository-names technova-api --query '"'"'repositories[0].[repositoryUri,imageScanningConfiguration.scanOnPush]'"'"' --output text; aws ecr describe-images --repository-name technova-api --query '"'"'sort_by(imageDetails,&imagePushedAt)[].[imagePushedAt,join(`, `,imageTags||[`<untagged>`]),imageDigest]'"'"' --output table'`
- **Shell:** direto · **diretório:** `/mnt/c/Users/lucas/unifaat-devops-portfolio`
- **Início:** 2026-10-23T12:17:04-03:00 · **fim:** 2026-10-23T12:17:08-03:00 · **duração:** 4.451 s
- **Código de retorno:** 0
- `002_121704_repositorio-ecr-technova-api-imagens-e-t.txt` — TXT — saída real do processo — SHA-256 `a2cc49015a8cf1dccac5e7a6c55c42b6aa8635e82feafb0ba48e5b4a141109ea`
- `002_121704_repositorio-ecr-technova-api-imagens-e-t_renderizada.png` — PNG — imagem renderizada (não é captura de tela) — SHA-256 `2180083faf2130397922ef027025ca1224978e6464934c9e5e729b9f3730bc5e`

### #003 — ECR technova-api: imagens com tag (sha-XXXXXXX por commit + latest), scan on push ativo

- **Comando:** `bash -c 'aws ecr describe-repositories --repository-names technova-api --query '"'"'repositories[0].[repositoryUri,imageScanningConfiguration.scanOnPush]'"'"' --output text; aws ecr describe-images --repository-name technova-api --filter tagStatus=TAGGED --query '"'"'sort_by(imageDetails,&imagePushedAt)[].[imagePushedAt,join(`,`,imageTags),imageSizeInBytes]'"'"' --output table'`
- **Shell:** direto · **diretório:** `/mnt/c/Users/lucas/unifaat-devops-portfolio`
- **Início:** 2026-10-23T12:17:18-03:00 · **fim:** 2026-10-23T12:17:22-03:00 · **duração:** 3.759 s
- **Código de retorno:** 0
- `003_121718_ecr-technova-api-imagens-com-tag-sha-xxx.txt` — TXT — saída real do processo — SHA-256 `528881160227a72c3cf47009aac210df417b666a8155fb132d703e0752430d99`
- `003_121718_ecr-technova-api-imagens-com-tag-sha-xxx_renderizada.png` — PNG — imagem renderizada (não é captura de tela) — SHA-256 `2807d67eba5fc73eaf2b985bb6b61029b21cf866cd4d0f7af5449594f2080e40`

## Verificação de integridade

- ✅ Todos os arquivos existem e conferem com o SHA-256 registrado.
