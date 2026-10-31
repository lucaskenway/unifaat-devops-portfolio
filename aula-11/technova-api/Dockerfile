# ============================================
# Estágio 1: dependências de produção
# ============================================
FROM node:20-alpine AS builder
WORKDIR /app

# package*.json primeiro: a camada do npm ci só é refeita quando as deps mudam
COPY package*.json ./
RUN npm ci --omit=dev && npm cache clean --force

# ============================================
# Estágio 2: runtime (imagem final)
# ============================================
FROM node:20-alpine AS runtime

LABEL org.opencontainers.image.source="https://github.com/lucaskenway/unifaat-devops-portfolio"
LABEL org.opencontainers.image.description="TechNova API - Sistema de gestão de pedidos"

ENV NODE_ENV=production
WORKDIR /app

# Patches de segurança do Alpine + remove npm/corepack (não são usados em runtime e
# trazem dependências com CVEs) + usuário não-root dedicado
RUN apk upgrade --no-cache && \
    rm -rf /usr/local/lib/node_modules /usr/local/bin/npm /usr/local/bin/npx \
           /usr/local/bin/corepack /opt/yarn* /usr/local/bin/yarn /usr/local/bin/yarnpkg && \
    addgroup -g 1001 -S nodejs && \
    adduser -S technova -u 1001 -G nodejs

COPY --from=builder --chown=technova:nodejs /app/node_modules ./node_modules
COPY --chown=technova:nodejs package.json server.js ./

USER technova
EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:3000/health || exit 1

CMD ["node", "server.js"]
