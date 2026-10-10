# Aula 08 — GitHub Actions: CI Completo com Secrets

[![CI Pipeline — Aula 08](https://github.com/lucaskenway/unifaat-devops-portfolio/actions/workflows/ci-aula08.yml/badge.svg)](https://github.com/lucaskenway/unifaat-devops-portfolio/actions/workflows/ci-aula08.yml)

Pipeline de CI da **TechNova API** (Node.js/Express) com lint, testes, build Docker e secrets.

## Estrutura

```
.github/workflows/
├── ci-aula08.yml      # CI: lint → test → build (+ verify-credentials, comentário no PR)
├── secrets-demo.yml   # demo de mascaramento de secrets (manual)
└── deploy.yml         # deploy simulado staging → production com approval gate (manual)
aula-08/
├── technova-api/
│   ├── server.js
│   ├── __tests__/server.test.js
│   ├── .eslintrc.json
│   ├── Dockerfile
│   └── package.json
└── screenshots/
```

## Pipeline

```
push/PR → lint (ESLint) → test (Jest, Node 18 + 20) → build (Docker + smoke test) → comentário no PR
```

| Job | O que faz |
|-----|-----------|
| `lint` | `npm run lint` — ESLint com regras `semi`, `quotes`, `no-unused-vars`, `indent` |
| `test` | `npm run test:ci` — 9 testes Jest com coverage, em matrix Node 18/20; coverage salvo como artifact |
| `build` | Valida os secrets, `docker build -t technova-api:${{ github.sha }}`, sobe o container e checa `/health` |
| `verify-credentials` | Só em push na main: confere se as credenciais AWS existem |
| `pr-comment` | Em PRs, comenta (ou atualiza) o resultado de cada job via `GITHUB_TOKEN` |

Extras: cache npm via `setup-node` + cache de `node_modules` (`actions/cache`), `concurrency` cancelando execuções antigas e filtro de `paths`.

### Deploy com environments

`deploy.yml` (disparo manual): `CI Checks` → `Deploy to Staging` → `Deploy to Production`.
O environment `production` exige aprovação (required reviewer) e só aceita deploy da branch `main`.

## Secrets usados

Configurados em **Settings → Secrets and variables → Actions** (valores fictícios):

| Secret | Uso |
|--------|-----|
| `AWS_REGION` | Obrigatório — validado no job `build` (aparece como `***` no log) |
| `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` | `verify-credentials` e `secrets-demo` |
| `DB_PASSWORD` | `secrets-demo` (só o tamanho é impresso) |

Environment secrets (`staging` e `production`): `DB_HOST`, `DB_NAME`.

## Rodando localmente

```bash
cd aula-08/technova-api
npm ci
npm run lint
npm test
docker build -t technova-api .
docker run -p 3000:3000 technova-api
curl http://localhost:3000/health
```

## Endpoints

| Método | Rota | Descrição |
|--------|------|-----------|
| GET | `/health` | Health check |
| GET | `/api/orders` | Lista pedidos |
| GET | `/api/orders/:id` | Busca pedido (404 se não existir) |
| POST | `/api/orders` | Cria pedido (`product`, `quantity`) |

## Screenshots

Ver [`screenshots/`](screenshots/):
- `screenshot-pipeline-passing.png`
- `screenshot-pipeline-failing.png`
- `screenshot-secrets-configured.png`
