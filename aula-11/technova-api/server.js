const express = require('express');
const cors = require('cors');
const { version } = require('./package.json');

const app = express();

app.use(cors());
app.use(express.json());

// Cor do ambiente (blue/green) injetada pelo deploy — aparece no /health e no /version
// para provar, pelo DNS do ALB, qual Target Group está recebendo o tráfego
const color = process.env.APP_COLOR || 'local';

// Injeção de falha para testar o rollback do Blue/Green: com SIMULATE_ERRORS=true o
// /health continua 200 (o Target Group fica healthy e o switch acontece), mas a API de
// pedidos responde 500 — só a validação pós-switch do workflow detecta e reverte
const simulateErrors = process.env.SIMULATE_ERRORS === 'true';

const orders = [
  { id: 1, product: 'Notebook TechNova Pro', quantity: 2, status: 'pending' },
  { id: 2, product: 'Monitor UltraWide 34"', quantity: 1, status: 'shipped' },
  { id: 3, product: 'Teclado Mecânico RGB', quantity: 5, status: 'delivered' }
];

// Health check
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    version,
    color
  });
});

// Health check profundo (readiness): além de responder, confere se a camada de dados
// atende uma leitura e se o processo não está sem memória. É o path do health check
// dos Target Groups — um target só entra em serviço se a API consegue servir pedidos.
app.get('/health/ready', (req, res) => {
  const heapUsedMb = Math.round(process.memoryUsage().heapUsed / 1024 / 1024);
  const checks = {
    ordersStore: Array.isArray(orders) && orders.length > 0 ? 'ok' : 'fail',
    memory: heapUsedMb < 256 ? 'ok' : 'fail'
  };
  const ready = Object.values(checks).every(c => c === 'ok');
  res.status(ready ? 200 : 503).json({
    status: ready ? 'ready' : 'not_ready',
    color,
    uptimeSeconds: Math.round(process.uptime()),
    heapUsedMb,
    checks
  });
});

// Versão em execução — o pipeline CD injeta GITHUB_SHA e DEPLOY_TIME no docker run,
// então dá para conferir qual commit está no ar sem entrar na EC2
app.get('/version', (req, res) => {
  res.json({
    version,
    commit: process.env.GITHUB_SHA || 'local',
    deployedAt: process.env.DEPLOY_TIME || null,
    color
  });
});

// Orders routes
app.use('/api', (req, res, next) => {
  if (simulateErrors) {
    return res.status(500).json({ error: 'Simulated failure (SIMULATE_ERRORS=true)' });
  }
  next();
});

app.get('/api/orders', (req, res) => {
  res.json(orders);
});

app.get('/api/orders/:id', (req, res) => {
  const order = orders.find(o => o.id === parseInt(req.params.id, 10));
  if (!order) {
    return res.status(404).json({ error: 'Order not found' });
  }
  res.json(order);
});

app.post('/api/orders', (req, res) => {
  const { product, quantity } = req.body;
  if (!product || !quantity) {
    return res.status(400).json({ error: 'Product and quantity are required' });
  }
  const newOrder = {
    id: orders.length + 1,
    product,
    quantity,
    status: 'pending'
  };
  orders.push(newOrder);
  res.status(201).json(newOrder);
});

// Só inicia o servidor se não estiver em modo de teste
if (process.env.NODE_ENV !== 'test') {
  const PORT = process.env.PORT || 3000;
  app.listen(PORT, () => {
    console.log(`TechNova API rodando na porta ${PORT}`); // ai-review-ignore: log único de startup
  });
}

module.exports = app;
