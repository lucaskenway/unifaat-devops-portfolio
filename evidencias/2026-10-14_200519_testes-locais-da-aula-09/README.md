# Evidências — testes-locais-da-aula-09

- **Projeto:** `unifaat-devops-portfolio`
- **Início da sessão:** 2026-10-14T20:05:19-03:00
- **Fim da sessão:** 2026-10-14T20:18:10-03:00
- **Ambiente:** WSL (Ubuntu) Ubuntu 26.04 LTS · usuário `lucaskenway` · host `DESKTOP-AMJ5UEC`
- **Comandos registrados:** 11 (9 com retorno 0, 2 com falha) · **capturas de tela:** 0

> Gerado pela ferramenta `evidencia`. Os TXT contêm a saída capturada diretamente dos processos, sem edição; a única alteração possível é a troca de dados sensíveis por `[REDIGIDO:tipo]`, sempre informada abaixo. Imagens **renderizadas** são desenhadas a partir do TXT e **não são capturas de tela**; capturas **autênticas** são cópias dos pixels da tela.

## Índice

| # | Horário | Descrição | Comando | Retorno | Arquivos |
|---|---------|-----------|---------|---------|----------|
| 001 | 20:09:50 | Lint (ESLint) da TechNova API | `cd aula-09/technova-api && npm ci --no-audit --no-fund && npm run lint` | ✅ 0 | [001_200950_lint-eslint-da-technova-api.txt](001_200950_lint-eslint-da-technova-api.txt) — TXT — saída real do processo<br>[001_200950_lint-eslint-da-technova-api_renderizada.png](001_200950_lint-eslint-da-technova-api_renderizada.png) — PNG — imagem renderizada (não é captura de tela) |
| 002 | 20:11:55 | Testes Jest com coverage | `cd aula-09/technova-api && npm run test:ci` | ✅ 0 | [002_201155_testes-jest-com-coverage.txt](002_201155_testes-jest-com-coverage.txt) — TXT — saída real do processo<br>[002_201155_testes-jest-com-coverage_renderizada.png](002_201155_testes-jest-com-coverage_renderizada.png) — PNG — imagem renderizada (não é captura de tela) |
| 003 | 20:13:10 | Validacao dos workflows com actionlint | `docker run --rm -v "$PWD:[REDIGIDO:chave=valor] -w /repo rhysd/actionlint:1.7.7 -no-color .github/workflows/ci-aula09.yml .github/workflows/ai-review-aula09.yml .github/workflows/security-scan-aula09.yml && echo 'actionlint: nenhum problema encontrado'` | ✅ 0 | [003_201310_validacao-dos-workflows-com-actionlint.txt](003_201310_validacao-dos-workflows-com-actionlint.txt) — TXT — saída real do processo<br>[003_201310_validacao-dos-workflows-com-actionlint_renderizada.png](003_201310_validacao-dos-workflows-com-actionlint_renderizada.png) — PNG — imagem renderizada (não é captura de tela) |
| 004 | 20:13:13 | Build da imagem multi-stage | `cd aula-09/technova-api && docker build -t technova-api:aula09 . && docker images technova-api:aula09` | ✅ 0 | [004_201313_build-da-imagem-multi-stage.txt](004_201313_build-da-imagem-multi-stage.txt) — TXT — saída real do processo<br>[004_201313_build-da-imagem-multi-stage_renderizada.png](004_201313_build-da-imagem-multi-stage_renderizada.png) — PNG — imagem renderizada (não é captura de tela) |
| 005 | 20:13:27 | Container: health check, usuario nao-root e HEALTHCHECK | `docker rm -f technova-aula09 >/dev/null 2>&1; docker run -d --name technova-aula09 -p 3000:3000 technova-api:aula09 && sleep 12 && curl -s http://localhost:3000/health && echo && echo "usuario: $(docker exec technova-aula09 whoami)" && docker inspect --format 'healthcheck: {{.State.Health.Status}}' technova-aula09` | ❌ 125 | [005_201327_container-health-check-usuario-nao-root.txt](005_201327_container-health-check-usuario-nao-root.txt) — TXT — saída real do processo<br>[005_201327_container-health-check-usuario-nao-root_renderizada.png](005_201327_container-health-check-usuario-nao-root_renderizada.png) — PNG — imagem renderizada (não é captura de tela) |
| 006 | 20:13:28 | Trivy: vulnerabilidades da imagem (CRITICAL/HIGH/MEDIUM) | `docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy:0.56.1 image --severity CRITICAL,HIGH,MEDIUM --ignore-unfixed --exit-code 1 -q technova-api:aula09 && echo 'Trivy image: 0 vulnerabilidades CRITICAL/HIGH/MEDIUM'` | ✅ 0 | [006_201328_trivy-vulnerabilidades-da-imagem-critica.txt](006_201328_trivy-vulnerabilidades-da-imagem-critica.txt) — TXT — saída real do processo<br>[006_201328_trivy-vulnerabilidades-da-imagem-critica_renderizada.png](006_201328_trivy-vulnerabilidades-da-imagem-critica_renderizada.png) — PNG — imagem renderizada (não é captura de tela) |
| 007 | 20:14:36 | Trivy: misconfiguracao do Dockerfile | `docker run --rm -v "$PWD/aula-09/technova-api:/src:ro" aquasec/trivy:0.56.1 config --exit-code 1 -q /src && echo 'Trivy config: nenhuma misconfiguracao'` | ✅ 0 | [007_201436_trivy-misconfiguracao-do-dockerfile.txt](007_201436_trivy-misconfiguracao-do-dockerfile.txt) — TXT — saída real do processo<br>[007_201436_trivy-misconfiguracao-do-dockerfile_renderizada.png](007_201436_trivy-misconfiguracao-do-dockerfile_renderizada.png) — PNG — imagem renderizada (não é captura de tela) |
| 008 | 20:16:13 | npm audit das dependencias de producao | `cd aula-09/technova-api && npm audit --omit=dev --audit-level=critical` | ✅ 0 | [008_201613_npm-audit-das-dependencias-de-producao.txt](008_201613_npm-audit-das-dependencias-de-producao.txt) — TXT — saída real do processo<br>[008_201613_npm-audit-das-dependencias-de-producao_renderizada.png](008_201613_npm-audit-das-dependencias-de-producao_renderizada.png) — PNG — imagem renderizada (não é captura de tela) |
| 009 | 20:16:15 | AI review: PR inseguro bloqueado pelo quality gate | `DIFF_FILE=aula-09/exemplos/pr-inseguro.diff REVIEW_OUTPUT=/tmp/review-inseguro.md FAIL_ON_CRITICAL=true node .github/scripts/ai-review.js` | ❌ 1 | [009_201615_ai-review-pr-inseguro-bloqueado-pelo-qua.txt](009_201615_ai-review-pr-inseguro-bloqueado-pelo-qua.txt) — TXT — saída real do processo<br>[009_201615_ai-review-pr-inseguro-bloqueado-pelo-qua_renderizada.png](009_201615_ai-review-pr-inseguro-bloqueado-pelo-qua_renderizada.png) — PNG — imagem renderizada (não é captura de tela) |
| 010 | 20:16:16 | AI review: PR corrigido aprovado pelo quality gate | `DIFF_FILE=aula-09/exemplos/pr-corrigido.diff REVIEW_OUTPUT=/tmp/review-corrigido.md FAIL_ON_CRITICAL=true node .github/scripts/ai-review.js` | ✅ 0 | [010_201616_ai-review-pr-corrigido-aprovado-pelo-qua.txt](010_201616_ai-review-pr-corrigido-aprovado-pelo-qua.txt) — TXT — saída real do processo<br>[010_201616_ai-review-pr-corrigido-aprovado-pelo-qua_renderizada.png](010_201616_ai-review-pr-corrigido-aprovado-pelo-qua_renderizada.png) — PNG — imagem renderizada (não é captura de tela) |
| 011 | 20:16:34 | Container: health check, usuario nao-root e HEALTHCHECK (porta 3009) | `docker rm -f technova-aula09 >/dev/null 2>&1; docker run -d --name technova-aula09 -p 3009:3000 technova-api:aula09 && sleep 12 && curl -s http://localhost:3009/health && echo && echo "usuario: $(docker exec technova-aula09 whoami)" && docker inspect --format 'healthcheck: {{.State.Health.Status}}' technova-aula09` | ✅ 0 | [011_201634_container-health-check-usuario-nao-root.txt](011_201634_container-health-check-usuario-nao-root.txt) — TXT — saída real do processo<br>[011_201634_container-health-check-usuario-nao-root_renderizada.png](011_201634_container-health-check-usuario-nao-root_renderizada.png) — PNG — imagem renderizada (não é captura de tela) |

## Detalhes

### #001 — Lint (ESLint) da TechNova API

- **Comando:** `cd aula-09/technova-api && npm ci --no-audit --no-fund && npm run lint`
- **Shell:** bash · **diretório:** `/mnt/c/Users/lucas/unifaat-devops-portfolio`
- **Início:** 2026-10-14T20:09:50-03:00 · **fim:** 2026-10-14T20:11:54-03:00 · **duração:** 123.292 s
- **Código de retorno:** 0
- `001_200950_lint-eslint-da-technova-api.txt` — TXT — saída real do processo — SHA-256 `26daadf04d0d27af3b26d61f4ac649f1df4b55b5b7e17fa15c1c78e96981902c`
- `001_200950_lint-eslint-da-technova-api_renderizada.png` — PNG — imagem renderizada (não é captura de tela) — SHA-256 `40741d237cf93eacdf205e862260ea2d984a3f9bade71993c1d54dc8704c9e3a`

### #002 — Testes Jest com coverage

- **Comando:** `cd aula-09/technova-api && npm run test:ci`
- **Shell:** bash · **diretório:** `/mnt/c/Users/lucas/unifaat-devops-portfolio`
- **Início:** 2026-10-14T20:11:55-03:00 · **fim:** 2026-10-14T20:13:10-03:00 · **duração:** 74.971 s
- **Código de retorno:** 0
- `002_201155_testes-jest-com-coverage.txt` — TXT — saída real do processo — SHA-256 `51562bd48758b5e91fc34cdf68e74364984a0de3d10c043db530e18a9fb79f3c`
- `002_201155_testes-jest-com-coverage_renderizada.png` — PNG — imagem renderizada (não é captura de tela) — SHA-256 `54251d9bdb43a590a1ba0eb9cd298feef39f1899008b739a96daadbc95b026d5`

### #003 — Validacao dos workflows com actionlint

- **Comando:** `docker run --rm -v "$PWD:[REDIGIDO:chave=valor] -w /repo rhysd/actionlint:1.7.7 -no-color .github/workflows/ci-aula09.yml .github/workflows/ai-review-aula09.yml .github/workflows/security-scan-aula09.yml && echo 'actionlint: nenhum problema encontrado'`
- **Shell:** bash · **diretório:** `/mnt/c/Users/lucas/unifaat-devops-portfolio`
- **Início:** 2026-10-14T20:13:10-03:00 · **fim:** 2026-10-14T20:13:13-03:00 · **duração:** 2.151 s
- **Código de retorno:** 0
- ⚠️ **Dados sensíveis redigidos:** chave=valor ×1
- `003_201310_validacao-dos-workflows-com-actionlint.txt` — TXT — saída real do processo — SHA-256 `9531d94219f2fa2d3bc25d1f831799c162d6d47f437f658c380de3b48ca8b68d`
- `003_201310_validacao-dos-workflows-com-actionlint_renderizada.png` — PNG — imagem renderizada (não é captura de tela) — SHA-256 `11850511846261d28a78ed330a4eeeab721bf087a2847002ac7771ade557a4b6`

### #004 — Build da imagem multi-stage

- **Comando:** `cd aula-09/technova-api && docker build -t technova-api:aula09 . && docker images technova-api:aula09`
- **Shell:** bash · **diretório:** `/mnt/c/Users/lucas/unifaat-devops-portfolio`
- **Início:** 2026-10-14T20:13:13-03:00 · **fim:** 2026-10-14T20:13:15-03:00 · **duração:** 2.206 s
- **Código de retorno:** 0
- `004_201313_build-da-imagem-multi-stage.txt` — TXT — saída real do processo — SHA-256 `7bcbfaf3e2c22a612c2bf48eef14e3d0e1f8c149ce886520426d65d0bf8f0b89`
- `004_201313_build-da-imagem-multi-stage_renderizada.png` — PNG — imagem renderizada (não é captura de tela) — SHA-256 `5b724766edc3c28da2f894f4a1b5bab6efb8391e9e76d96c35a7a4e7b25a623e`

### #005 — Container: health check, usuario nao-root e HEALTHCHECK

- **Comando:** `docker rm -f technova-aula09 >/dev/null 2>&1; docker run -d --name technova-aula09 -p 3000:3000 technova-api:aula09 && sleep 12 && curl -s http://localhost:3000/health && echo && echo "usuario: $(docker exec technova-aula09 whoami)" && docker inspect --format 'healthcheck: {{.State.Health.Status}}' technova-aula09`
- **Shell:** bash · **diretório:** `/mnt/c/Users/lucas/unifaat-devops-portfolio`
- **Início:** 2026-10-14T20:13:27-03:00 · **fim:** 2026-10-14T20:13:27-03:00 · **duração:** 0.775 s
- **Código de retorno:** 125
- `005_201327_container-health-check-usuario-nao-root.txt` — TXT — saída real do processo — SHA-256 `f4ca0e1085674b3461064fd52dee007bd30a6163765e023bb0d39fb4d7a851f6`
- `005_201327_container-health-check-usuario-nao-root_renderizada.png` — PNG — imagem renderizada (não é captura de tela) — SHA-256 `9683c72b90cad0dd2cacca64b2baae74005f7a6ea547c149ac096242537c0fdc`

### #006 — Trivy: vulnerabilidades da imagem (CRITICAL/HIGH/MEDIUM)

- **Comando:** `docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy:0.56.1 image --severity CRITICAL,HIGH,MEDIUM --ignore-unfixed --exit-code 1 -q technova-api:aula09 && echo 'Trivy image: 0 vulnerabilidades CRITICAL/HIGH/MEDIUM'`
- **Shell:** bash · **diretório:** `/mnt/c/Users/lucas/unifaat-devops-portfolio`
- **Início:** 2026-10-14T20:13:28-03:00 · **fim:** 2026-10-14T20:14:34-03:00 · **duração:** 65.871 s
- **Código de retorno:** 0
- `006_201328_trivy-vulnerabilidades-da-imagem-critica.txt` — TXT — saída real do processo — SHA-256 `64cb434e71a59723950e122ce69fd1c5a4b09b4a75434d4ed8f4c2532d29e49d`
- `006_201328_trivy-vulnerabilidades-da-imagem-critica_renderizada.png` — PNG — imagem renderizada (não é captura de tela) — SHA-256 `d8c562dcc9e830da26a166a0886eb605b221cd9804850da6cb3849fb25aa6a9e`

### #007 — Trivy: misconfiguracao do Dockerfile

- **Comando:** `docker run --rm -v "$PWD/aula-09/technova-api:/src:ro" aquasec/trivy:0.56.1 config --exit-code 1 -q /src && echo 'Trivy config: nenhuma misconfiguracao'`
- **Shell:** bash · **diretório:** `/mnt/c/Users/lucas/unifaat-devops-portfolio`
- **Início:** 2026-10-14T20:14:36-03:00 · **fim:** 2026-10-14T20:16:10-03:00 · **duração:** 94.283 s
- **Código de retorno:** 0
- `007_201436_trivy-misconfiguracao-do-dockerfile.txt` — TXT — saída real do processo — SHA-256 `b22509655412803bfe6da598b01ed163e5eb326d9b0d04315667fdce99b854cb`
- `007_201436_trivy-misconfiguracao-do-dockerfile_renderizada.png` — PNG — imagem renderizada (não é captura de tela) — SHA-256 `951635c2498495ccda2a98e5086fbd002d805edc7c07a115c48a8c1333b2e09c`

### #008 — npm audit das dependencias de producao

- **Comando:** `cd aula-09/technova-api && npm audit --omit=dev --audit-level=critical`
- **Shell:** bash · **diretório:** `/mnt/c/Users/lucas/unifaat-devops-portfolio`
- **Início:** 2026-10-14T20:16:13-03:00 · **fim:** 2026-10-14T20:16:15-03:00 · **duração:** 1.675 s
- **Código de retorno:** 0
- `008_201613_npm-audit-das-dependencias-de-producao.txt` — TXT — saída real do processo — SHA-256 `fd749addea529da844b5ae30b8c894bf9ed2d3e8bb297c5ddbf0d8e9fbef7d24`
- `008_201613_npm-audit-das-dependencias-de-producao_renderizada.png` — PNG — imagem renderizada (não é captura de tela) — SHA-256 `2d34389f13b7ee419e7a697752dd39fe159b092571afe31e7bf93ea7f81ce2ba`

### #009 — AI review: PR inseguro bloqueado pelo quality gate

- **Comando:** `DIFF_FILE=aula-09/exemplos/pr-inseguro.diff REVIEW_OUTPUT=/tmp/review-inseguro.md FAIL_ON_CRITICAL=true node .github/scripts/ai-review.js`
- **Shell:** bash · **diretório:** `/mnt/c/Users/lucas/unifaat-devops-portfolio`
- **Início:** 2026-10-14T20:16:15-03:00 · **fim:** 2026-10-14T20:16:16-03:00 · **duração:** 0.147 s
- **Código de retorno:** 1
- `009_201615_ai-review-pr-inseguro-bloqueado-pelo-qua.txt` — TXT — saída real do processo — SHA-256 `73d5753522eccd67f61f9d397bcbb719457c591d169d04d86cf99ad27ef00cb5`
- `009_201615_ai-review-pr-inseguro-bloqueado-pelo-qua_renderizada.png` — PNG — imagem renderizada (não é captura de tela) — SHA-256 `5668cba2fe90735030e29ab0da139e49dd408aeffb4154d81e42accb21b3087b`

### #010 — AI review: PR corrigido aprovado pelo quality gate

- **Comando:** `DIFF_FILE=aula-09/exemplos/pr-corrigido.diff REVIEW_OUTPUT=/tmp/review-corrigido.md FAIL_ON_CRITICAL=true node .github/scripts/ai-review.js`
- **Shell:** bash · **diretório:** `/mnt/c/Users/lucas/unifaat-devops-portfolio`
- **Início:** 2026-10-14T20:16:16-03:00 · **fim:** 2026-10-14T20:16:16-03:00 · **duração:** 0.140 s
- **Código de retorno:** 0
- `010_201616_ai-review-pr-corrigido-aprovado-pelo-qua.txt` — TXT — saída real do processo — SHA-256 `2af39c1e75189ad0bc67b49cf3e16392562ac56670a1933861c09413be3d81b4`
- `010_201616_ai-review-pr-corrigido-aprovado-pelo-qua_renderizada.png` — PNG — imagem renderizada (não é captura de tela) — SHA-256 `c9f5475d0c4602d66fdcf57686a1d78c3bf9371adfffaf677f180382fdb6fca5`

### #011 — Container: health check, usuario nao-root e HEALTHCHECK (porta 3009)

- **Comando:** `docker rm -f technova-aula09 >/dev/null 2>&1; docker run -d --name technova-aula09 -p 3009:3000 technova-api:aula09 && sleep 12 && curl -s http://localhost:3009/health && echo && echo "usuario: $(docker exec technova-aula09 whoami)" && docker inspect --format 'healthcheck: {{.State.Health.Status}}' technova-aula09`
- **Shell:** bash · **diretório:** `/mnt/c/Users/lucas/unifaat-devops-portfolio`
- **Início:** 2026-10-14T20:16:34-03:00 · **fim:** 2026-10-14T20:16:47-03:00 · **duração:** 13.332 s
- **Código de retorno:** 0
- `011_201634_container-health-check-usuario-nao-root.txt` — TXT — saída real do processo — SHA-256 `371b11c32c61a4ca7e0508b3ed13295c3550e8294d7c37b6082993b1394adac9`
- `011_201634_container-health-check-usuario-nao-root_renderizada.png` — PNG — imagem renderizada (não é captura de tela) — SHA-256 `e385cd4f5aee3ee4e0d7e052fffe82dff5db5848aece8b91754779c3cfd95a2f`

## Verificação de integridade

- ✅ Todos os arquivos existem e conferem com o SHA-256 registrado.
