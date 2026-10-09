# Aula 08 — GitHub Actions: CI Completo com Secrets

[![CI Pipeline — Aula 08](https://github.com/lucaskenway/unifaat-devops-portfolio/actions/workflows/ci-aula08.yml/badge.svg)](https://github.com/lucaskenway/unifaat-devops-portfolio/actions/workflows/ci-aula08.yml)

Pipeline de CI da **TechNova API** (Node.js/Express) com lint, testes, build Docker e secrets.

## Estrutura

```
.github/workflows/ci-aula08.yml   # workflow (fica na raiz do repositório)
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
| `pr-comment` | Em PRs, comenta o resultado de cada job via `GITHUB_TOKEN` |

Extras: cache npm via `setup-node`, `concurrency` cancelando execuções antigas e filtro de `paths`.

## Secrets usados

Configurados em **Settings → Secrets and variables → Actions** (valores fictícios):

| Secret | Uso |
|--------|-----|
| `AWS_REGION` | Obrigatório — validado no job `build` (aparece como `***` no log) |
| `AWS_ACCESS_KEY_ID` | Opcional — apenas verificado se existe |

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
