# Análise do Uso de IA — Aula 02 TF

## Prompt Utilizado

> Crie um docker-compose.yml para uma aplicação Node.js 20 com Express que usa PostgreSQL 15 como banco de dados e Redis 7 como cache. A API roda na porta 3000. O PostgreSQL precisa de volume nomeado para persistência. Todos os serviços devem estar na mesma rede bridge customizada. Use variáveis de ambiente com interpolação de arquivo .env. Adicione healthchecks, depends_on com condition, e restart policy unless-stopped.

---

## Output Original do Kiro

```yaml
name: node-api-stack

# Carrega variáveis do arquivo .env automaticamente
# Uso: docker compose --env-file .env up

services:

  # ─────────────────────────────────────────────
  # Banco de dados PostgreSQL 15
  # ─────────────────────────────────────────────
  postgres:
    image: postgres:15-alpine
    container_name: postgres
    restart: unless-stopped
    environment:
      POSTGRES_DB:       ${POSTGRES_DB}
      POSTGRES_USER:     ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
    ports:
      - "${POSTGRES_PORT:-5432}:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - app_network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER} -d ${POSTGRES_DB}"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 30s

  # ─────────────────────────────────────────────
  # Cache Redis 7
  # ─────────────────────────────────────────────
  redis:
    image: redis:7-alpine
    container_name: redis
    restart: unless-stopped
    command: >
      redis-server
      --requirepass ${REDIS_PASSWORD}
      --appendonly yes
    ports:
      - "${REDIS_PORT:-6379}:6379"
    networks:
      - app_network
    healthcheck:
      test: ["CMD", "redis-cli", "-a", "${REDIS_PASSWORD}", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 10s

  # ─────────────────────────────────────────────
  # API Node.js 20 com Express
  # ─────────────────────────────────────────────
  api:
    image: node:20-alpine
    container_name: api
    restart: unless-stopped
    working_dir: /app
    # Monta o código-fonte e instala dependências na inicialização
    command: sh -c "npm install && node server.js"
    environment:
      NODE_ENV:          ${NODE_ENV:-production}
      PORT:              ${API_PORT:-3000}
      POSTGRES_HOST:     ${POSTGRES_HOST:-postgres}
      POSTGRES_PORT:     ${POSTGRES_PORT:-5432}
      POSTGRES_DB:       ${POSTGRES_DB}
      POSTGRES_USER:     ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      REDIS_HOST:        ${REDIS_HOST:-redis}
      REDIS_PORT:        ${REDIS_PORT:-6379}
      REDIS_PASSWORD:    ${REDIS_PASSWORD}
    ports:
      - "${API_PORT:-3000}:3000"
    volumes:
      - ./app:/app
    networks:
      - app_network
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
    healthcheck:
      test: ["CMD-SHELL", "wget -qO- http://localhost:${API_PORT:-3000}/health || exit 1"]
      interval: 15s
      timeout: 5s
      retries: 3
      start_period: 30s

volumes:
  postgres_data:
    driver: local

networks:
  app_network:
    driver: bridge
```

---

## Alterações que Fiz Manualmente

| O que mudei | Por quê |
|---|---|
| Ajustei o `.env` com as variáveis reais do projeto (`POSTGRES_DB=technova`, `DB_HOST=postgres`, etc.) | O Kiro gerou um `.env` genérico com nomes de placeholder. O projeto usa convenção `DB_HOST`/`DB_NAME` no `app.js`, não `POSTGRES_HOST` |
| Removi `REDIS_PASSWORD` do `.env` | O `app.js` não implementa autenticação no Redis; adicionar senha quebraria a conexão sem código de suporte |
| Substituí `image: node:20-alpine` + `command: npm install` por um `Dockerfile` próprio com `COPY` e `RUN npm install --production` | O Kiro usou a imagem base do Node e rodava `npm install` a cada `docker compose up`, o que é lento e inadequado para produção. O `Dockerfile` correto instala dependências na build |
| Corrigido o volume da API: de `./app:/app` para montar o diretório raiz `./` | O `app.js` fica na raiz de `aula-02/`, não em um subdiretório `app/`. O mapeamento do Kiro resultaria em container vazio |
| Troquei `node server.js` por `node app.js` no comando de execução | O arquivo de entrada do projeto é `app.js`, não `server.js` como o Kiro assumiu |
| Adicionei `build: .` no serviço `api` referenciando o `Dockerfile` criado | O Kiro não considerou a existência de um Dockerfile e gerou o serviço com imagem base |

---

## O que o Kiro Acertou

- Estrutura geral do `docker-compose.yml` com três serviços bem organizados
- Uso correto de `depends_on` com `condition: service_healthy` — garante ordem de inicialização
- Healthchecks funcionais para os três serviços (`pg_isready`, `redis-cli ping`, `wget /health`)
- `restart: unless-stopped` aplicado em todos os serviços corretamente
- Volume nomeado `postgres_data` com `driver: local` para persistência do banco
- Rede bridge customizada `app_network` isolando todos os serviços
- Interpolação de variáveis com valores default (ex: `${POSTGRES_PORT:-5432}`) — boa prática
- Redis configurado com `--appendonly yes` para persistência dos dados em memória
- Comentários explicativos em todo o arquivo, úteis para aprendizado

---

## O que o Kiro Errou ou Omitiu

- **Nome do arquivo de entrada errado:** assumiu `server.js` em vez de `app.js`, o que causaria erro imediato ao subir o container
- **Volume do código-fonte incorreto:** mapeou `./app:/app` mas o código está na raiz (`./`), o container ficaria vazio
- **Ignorou o Dockerfile:** o projeto já tinha (ou precisava de) um `Dockerfile` com `COPY` e `npm install --production`; usar `image: node:20-alpine` com install inline é ruim para produção
- **Nomes de variáveis inconsistentes com o app.js:** gerou `POSTGRES_HOST` mas o `app.js` lê `DB_HOST`; sem ajuste manual a API não conectaria ao banco
- **Redis com senha sem suporte no código:** incluiu `REDIS_PASSWORD` mas o `app.js` não implementa autenticação Redis — a conexão quebraria
- **Não gerou o Dockerfile** — parte essencial do stack que ficou de fora da entrega inicial
- **`.env` com valores genéricos:** usou `appdb`/`appuser`/`supersecret` sem considerar as convenções do projeto

---

## Minha Avaliação

- **Tempo economizado usando IA:** ~25 minutos (estrutura base, healthchecks, sintaxe do compose)
- **Tempo gasto validando/corrigindo:** ~15 minutos (ajustar variáveis, corrigir volume, checar nomes)
- **Nota para o output da IA (1-10):** 7
- **Usaria novamente para este tipo de tarefa?** Sim — o Kiro entrega uma base sólida e tecnicamente correta em conceitos (healthchecks, depends_on, redes, volumes). O esforço de validação é pequeno comparado ao tempo de escrever do zero. Para projetos reais, o passo crítico é sempre confrontar o output com o código existente antes de usar.
