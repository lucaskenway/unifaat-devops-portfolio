const express = require('express');
const cors = require('cors');
const { version } = require('./package.json');
const featureFlags = require('./src/feature-flags');
const metricsMiddleware = require('./src/middleware/metrics-middleware');
const flagsRouter = require('./routes/flags');
const ordersRouter = require('./routes/orders');

const app = express();

app.use(cors());
app.use(express.json());
app.use(metricsMiddleware);

// Injeção de falhas para demonstrar o rollback automático e o AIOps:
//   FAIL_HEALTHCHECK=true  → /health responde 503 (simula um deploy quebrado:
//                            o pipeline detecta na janela de observação e reverte)
//   SIMULATE_LATENCY_MS=N  → atraso artificial em /api (dispara o alarme de latência)
//   SIMULATE_ERRORS=true   → /api responde 500 (dispara o alarme de 5xx)
const failHealthcheck = process.env.FAIL_HEALTHCHECK === 'true';
const simulateLatencyMs = parseInt(process.env.SIMULATE_LATENCY_MS || '0', 10);
const simulateErrors = process.env.SIMULATE_ERRORS === 'true';

// Health check (liveness) — é o que o pipeline observa depois do deploy
app.get('/health', (req, res) => {
  const body = {
    status: failHealthcheck ? 'unhealthy' : 'ok',
    timestamp: new Date().toISOString(),
    version,
    commit: process.env.GITHUB_SHA || 'local'
  };
  res.status(failHealthcheck ? 503 : 200).json(body);
});

// Versão em execução — o pipeline usa o commit para saber qual imagem (sha-<commit>)
// está em produção ANTES do deploy, que é a imagem do rollback
app.get('/version', (req, res) => {
  res.json({
    version,
    commit: process.env.GITHUB_SHA || 'local',
    imageTag: process.env.IMAGE_TAG || null,
    deployedAt: process.env.DEPLOY_TIME || null,
    flags: featureFlags.getAllFlags()
  });
});

app.use('/flags', flagsRouter);

// Falhas simuladas só na API de negócio; /health e /version continuam respondendo
app.use('/api', (req, res, next) => {
  if (simulateErrors) {
    console.error('ERROR [orders] falha simulada (SIMULATE_ERRORS=true)');
    return res.status(500).json({ error: 'Simulated failure (SIMULATE_ERRORS=true)' });
  }
  if (simulateLatencyMs > 0) {
    return setTimeout(next, simulateLatencyMs);
  }
  next();
});

app.use('/api/orders', ordersRouter);

// Só inicia o servidor se não estiver em modo de teste
if (process.env.NODE_ENV !== 'test') {
  const PORT = process.env.PORT || 3000;
  app.listen(PORT, () => {
    console.log(`TechNova API ${version} rodando na porta ${PORT}`); // ai-review-ignore: log único de startup
  });
}

module.exports = app;
