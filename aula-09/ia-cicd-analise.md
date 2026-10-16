# IA no CI/CD — Análise da Estratégia (Aula 09)

Documento de decisões do pipeline da **TechNova API**: Docker Registry (Amazon ECR, via AWS Academy Learner Lab) + AI Code Review com quality gate.

---

## 0. Por que Amazon ECR (e não ghcr.io / Docker Hub)

| Critério | Amazon ECR | ghcr.io | Docker Hub |
|----------|-----------|---------|------------|
| Onde a imagem fica | Na **mesma conta AWS** onde a TechNova já roda EC2/RDS (aulas de Terraform) | GitHub | Docker Inc. |
| Pull pela infraestrutura | EC2/ECS/EKS puxam direto, com IAM (`LabInstanceProfile`), sem segredo extra | Imagem privada exige PAT no servidor | Precisa de login; rate limit no plano free |
| Visibilidade | Privado por padrão | Público ou privado | Público por padrão (privados limitados no free) |
| Segurança | Scan on push nativo, lifecycle policy, criptografia em repouso | Scan via ferramentas externas | Docker Scout (limitado no free) |
| Autenticação | Token temporário (`aws ecr get-login-password`, ~12h) | `GITHUB_TOKEN` no Actions | Usuário + token |

O motivo principal é **proximidade com o deploy**: o Módulo 4 vai subir a API na AWS, e com o ECR a imagem não sai da conta nem depende de credencial de terceiro no servidor.

**Restrições do Learner Lab e como foram tratadas:**

- **Credenciais temporárias** (`ASIA…` + `aws_session_token`) que mudam a cada sessão. Por isso o fluxo principal é o script local `technova-api/ecr-push.sh`, que valida a sessão com `aws sts get-caller-identity` antes de tudo e falha com uma mensagem clara quando ela venceu.
- **Sem IAM:** o Lab não deixa criar usuário, grupo ou role. Não dá para usar OIDC (o jeito certo em produção, sem segredo fixo) nem um usuário de deploy dedicado. O CI (`ci-aula09.yml`) usa as 3 credenciais da sessão como secrets e, quando estão ausentes ou expiradas, **pula o push com um aviso** em vez de deixar o pipeline vermelho por um motivo que não é do código.
- **Região fixa `us-east-1`** em tudo (script, workflow, URI).
- **Repositório criado antes do push**: diferente do ghcr.io, o ECR não cria o repositório no primeiro push. O script e o workflow garantem o `technova-api` de forma idempotente (`describe-repositories || create-repository`).

---

## 1. Estratégia de tagging

Imagem: `<ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/technova-api`

| Origem | Tags geradas | Para que serve |
|--------|--------------|----------------|
| `./ecr-push.sh` (ou push na `main` no CI) | `sha-XXXXXXX`, `latest` | `sha-` amarra a imagem ao commit exato; `latest` aponta para o último build publicado |
| `./ecr-push.sh 1.2.3` ou HEAD com git tag `v1.2.3` | `1.2.3`, `1.2`, `1`, `sha-XXXXXXX`, `latest` | Release imutável (`1.2.3`) + canais que acompanham patches (`1.2`) ou minors (`1`) |
| Pull Request (CI) | *nenhuma publicada* | A imagem é construída e passa pelo smoke test, mas **não** vai para o registry |

**Por que essa combinação:**

- **SHA como identidade.** É a única tag que nunca muda de significado: `sha-a1b2c3d` sempre é o mesmo código. É a tag que deploy e rollback devem usar, porque responde "o que está rodando em produção?" com um `git show`.
- **`latest` só como conveniência.** Serve para `docker pull` rápido e ambiente de dev. Não é usada em deploy: ela se move a cada push e torna o rollback ambíguo.
- **Semver para releases.** Quem consome a imagem escolhe o nível de estabilidade: `1.2.3` (fixo), `1.2` (recebe patches) ou `1` (recebe minors). Só é gerada a partir de uma decisão explícita de release (argumento do script ou git tag).
- **Nada de tag por branch.** `feature-x` vira lixo no registry e não identifica um build específico.

**Rollback:** `./ecr-rollback.sh 1.0.0` faz login, remove a cópia local, dá `docker pull` da tag no ECR e troca o container `technova-prod`, conferindo o `/health`. Como a tag de release é imutável por convenção, voltar para ela é determinístico.

**Push condicional (CI):** o login e o push no ECR só rodam quando `github.event_name != 'pull_request'` **e** a sessão do Lab é válida. Isso evita que código ainda não revisado vire imagem e não deixa o registry encher de imagens de PR. O build e o smoke test rodam também em PR, então um Dockerfile quebrado é detectado antes do merge.

**Cache de layers:** no CI, `cache-from/cache-to: type=gha` (escopo `technova-api`). O primeiro build popula o cache; o passo de push reaproveita as mesmas layers sem reconstruir.

**Higiene do registry (bônus):**

- **Scan on push** habilitado no repositório (`put-image-scanning-configuration scanOnPush=true`): cada imagem publicada é escaneada pelo ECR.
- **Lifecycle policy** (`technova-api/ecr-lifecycle-policy.json`): imagens sem tag expiram em 1 dia (sobram quando um `sha-`/`latest` é reaplicado num build novo) e só os 15 builds `sha-*` mais recentes são mantidos. Ressalva: a regra de contagem olha a tag `sha-*` e uma imagem de release também carrega essa tag, então uma release muito antiga pode expirar depois de 15 builds novos. Para o volume do portfólio é aceitável; em produção as releases iriam para um repositório próprio ou a regra usaria uma tag específica de build.

---

## 2. Padrões verificados pelo AI review

O script `.github/scripts/ai-review.js` analisa **somente as linhas adicionadas** no diff do PR (o código removido não interessa) e reporta arquivo + linha real do arquivo novo (calculada a partir dos cabeçalhos `@@` do diff).

| # | Regra | Severidade | Escopo | O que detecta |
|---|-------|:----------:|--------|---------------|
| 1 | `hardcoded-secret` | 🔴 CRITICAL | todos | `password/secret/token/api_key... = '<literal>'` |
| 2 | `aws-access-key` | 🔴 CRITICAL | todos | `AKIA…`/`ASIA…` (Access Key ID) |
| 3 | `private-key` | 🔴 CRITICAL | todos | `-----BEGIN ... PRIVATE KEY-----` |
| 4 | `eval` | 🔴 CRITICAL | JS/TS | `eval(` |
| 5 | `new-function` | 🔴 CRITICAL | JS/TS | `new Function(` |
| 6 | `sql-injection` | 🔴 CRITICAL | JS/TS | SQL montado com `+` ou `${}` (`query('SELECT ...' + x)`) |
| 7 | `command-injection` | 🔴 CRITICAL | JS/TS | `exec/spawn` com template literal ou concatenação |
| 8 | `tls-disabled` | 🔴 CRITICAL | todos | `rejectUnauthorized: false`, `NODE_TLS_REJECT_UNAUTHORIZED=0` |
| 9 | `xss-sink` | 🟡 WARNING | JS/TS | `innerHTML =`, `document.write(`, `dangerouslySetInnerHTML` |
| 10 | `cors-wildcard` | 🟡 WARNING | todos | `origin: '*'` |
| 11 | `bind-all-interfaces` | 🟡 WARNING | todos | `listen(..., '0.0.0.0')`, `--host 0.0.0.0` |
| 12 | `open-cidr` | 🟡 WARNING | `.tf`/`.tfvars`/YAML/JSON | `0.0.0.0/0` ou `::/0` (ex.: SSH aberto) |
| 13 | `console-log` | 🟡 WARNING | JS/TS (exceto testes) | `console.log/debug/info(` |
| 14 | `empty-catch` | 🟡 WARNING | JS/TS | `catch (e) {}` |
| 15 | `debugger` | 🟡 WARNING | JS/TS | `debugger;` |
| 16 | `docker-latest` | 🟡 WARNING | Dockerfile | `FROM imagem:latest` |
| 17 | `docker-root` | 🟡 WARNING | Dockerfile | `USER root` |
| 18 | `chmod-777` | 🟡 WARNING | todos | `chmod 777` |
| 19 | `todo` | 🔵 INFO | todos | `TODO`, `FIXME`, `HACK`, `XXX` |
| 20 | `var` | 🔵 INFO | JS/TS | declaração com `var` |

Detalhes de implementação:

- **Secrets mascarados no comentário.** Quando a regra é de credencial, o trecho de código no comentário vira `'Su****'`. Sem isso, o próprio bot republicaria o secret no PR.
- **Arquivos ignorados:** `*.md`, `*.txt`, `*.diff`, `package-lock.json` e o próprio `ai-review.js` (que contém os padrões como texto).
- **Supressão explícita:** o comentário `ai-review-ignore` na linha descarta o achado, o que deixa o falso positivo registrado no código para o revisor humano ver.

---

## 3. Lógica de análise (e o prompt para IA)

### Fluxo no pipeline

```
PR aberto/atualizado
  → checkout (fetch-depth: 0)
  → git diff base.sha...head.sha  > /tmp/pr-diff.txt
  → node .github/scripts/ai-review.js
        ├─ parse do diff (arquivo atual, nº de linha do hunk)
        ├─ aplica as 20 regras nas linhas "+"
        ├─ gera /tmp/ai-review-result.md (tabela por severidade)
        └─ exporta critical / warning / info via $GITHUB_OUTPUT
  → github-script: cria OU atualiza o comentário (marcador <!-- technova-ai-review -->)
  → Quality gate: CRITICAL > 0 → exit 1
```

A implementação atual é **determinística** (regras/regex), equivalente à "Opção A" do laboratório: não tem custo por token, roda em qualquer fork e dá o mesmo resultado para o mesmo diff. O ponto de extensão para um LLM (Bedrock) é trocar o `analyzeDiff()` por uma chamada ao modelo, mantendo o mesmo formato de saída (lista de achados com severidade), para que comentário e quality gate continuem iguais.

### Prompt para a versão com LLM (Bedrock / Claude)

```text
Você é um revisor de código sênior da TechNova (API Node.js/Express em container).
Analise SOMENTE as linhas adicionadas (+) do diff abaixo.

Classifique cada achado em exatamente uma severidade:
- CRITICAL: vulnerabilidade explorável ou vazamento de credencial
  (secret hardcoded, injection SQL/comando, eval, TLS desabilitado).
- WARNING: problema de qualidade ou hardening que deve ser corrigido
  (catch vazio, console.log, XSS sink, container como root, CORS *).
- INFO: sugestão opcional de manutenção/estilo.

Regras:
- Não invente achados: se não houver evidência na linha, não reporte.
- Nunca repita o valor de um secret; descreva-o como "<redacted>".
- Para cada achado informe: arquivo, linha, severidade, problema, correção sugerida.
- Responda APENAS com JSON:
  {"findings":[{"file":"","line":0,"severity":"","message":"","fix":""}]}

Diff:
<<<DIFF (truncado em ~10.000 caracteres)>>>
```

Pedir **JSON estruturado** (e não Markdown livre) é o que permite manter o quality gate automático: o pipeline conta os `CRITICAL` em vez de interpretar texto.

---

## 4. Quality gate — lógica de decisão

| Resultado da análise | Job `AI Review` | Efeito no PR |
|----------------------|:---------------:|--------------|
| ≥ 1 CRITICAL | ❌ falha (`exit 1`) | Check vermelho; com branch protection exigindo o check, **merge bloqueado** |
| Só WARNING/INFO | ✅ passa | Merge liberado; o comentário lista os pontos para o autor avaliar |
| Nenhum achado | ✅ passa | Comentário "Nenhum problema encontrado" |
| Script falhou | ❌ falha | Comentário avisando a falha (*fail closed*: sem análise, não aprova) |

O comentário é postado **antes** do gate e com `if: always()`. Mesmo quando o job falha, o autor vê o motivo no PR sem precisar abrir os logs.

Para o bloqueio ser efetivo: *Settings → Branches → Branch protection rule (main) → Require status checks to pass → `AI Review`*.

**Por que WARNING não bloqueia:** essas regras têm taxa de falso positivo maior (ex.: o `console.log` de startup do `server.js` é intencional). Bloquear por elas ensinaria o time a ignorar ou desligar o bot.

---

## 5. Quando confiar na IA vs. exigir review humano

**Dá para confiar no review automático para:**

- Padrões mecânicos e objetivos: secrets, `eval`, `debugger`, `catch {}`, `FROM :latest`
- Consistência: o bot aplica a mesma régua em todo PR, às 3h da manhã ou na sexta à tarde
- Primeira passada em PRs grandes, onde a atenção humana cai

**Sempre exige review humano:**

- Regra de negócio: o bot não sabe que um pedido não pode ter `quantity <= 0`
- Arquitetura e design: acoplamento, nomes, se a mudança deveria existir
- Autenticação/autorização, dados pessoais (LGPD) e migrações de banco
- Qualquer achado CRITICAL que o autor marque como falso positivo: a supressão com `ai-review-ignore` precisa da aprovação de um humano
- Ausência de achados: **"0 achados" não significa "código seguro"**, só que nenhuma das regras casou

Regra prática do time: *o bot remove o óbvio da mesa; o humano revisa o que importa.*

---

## 6. Limitações identificadas

| Limitação | Exemplo concreto | Mitigação |
|-----------|------------------|-----------|
| **Falso positivo** | `console.log` de startup em `server.js` (único achado no próprio PR desta entrega) | Severidade WARNING (não bloqueia) + `ai-review-ignore` |
| **Falso negativo** | SQL montado em uma variável numa linha e executado em outra: `const q = 'SELECT..' + id;` em uma linha, `db.query(q)` na seguinte | Regex vê uma linha por vez; um LLM ou análise de fluxo (CodeQL) pegaria |
| **Contexto limitado ao diff** | Uma função insegura já existente e chamada pelo código novo não aparece | Review humano + scan do repositório inteiro (workflow de security scan) |
| **Secret ofuscado** | `'sk-' + 'abc' + '123'` ou base64 | Secret scanning do GitHub / gitleaks |
| **Diff grande / custo** | Com LLM, cada PR gera custo por token e o diff precisa ser truncado | Limitar a arquivos de código; aqui a versão por regras não tem custo |
| **PR de fork** | `GITHUB_TOKEN` é somente leitura em PRs de fork, então o comentário falha | Aceitável num portfólio individual; em projeto aberto usar `pull_request_target` com cuidado |
| **Não determinismo (LLM)** | O mesmo diff pode gerar respostas diferentes | Saída em JSON, temperatura baixa e gate baseado em contagem |

---

## 7. Security scan dedicado (bônus)

`security-scan-aula09.yml`, separado do CI e do AI review:

- **`npm audit --omit=dev --audit-level=critical`**: dependências de produção da API (resultado local: 0 vulnerabilidades)
- **Trivy config**: misconfiguração no Dockerfile (resultado local: 0 achados)
- **Trivy image**: relatório HIGH/CRITICAL; o gate falha em CRITICAL com correção disponível

Achado durante o desenvolvimento: a primeira versão da imagem tinha **1 CRITICAL e 25 HIGH**. Todos vinham do `npm` que já vem na `node:20-alpine` (ex.: `tar` CVE-2026-59873) e do OpenSSL do Alpine, não da aplicação. A correção no estágio de runtime foi `apk upgrade` e a remoção de `npm/npx/corepack/yarn`, que não são usados para rodar a API. Resultado: **0 CRITICAL / 0 HIGH / 0 MEDIUM** no Trivy 0.56.1.
