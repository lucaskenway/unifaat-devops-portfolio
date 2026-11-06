// src/middleware/metrics-middleware.js
// Mede o tempo de cada request e conta erros 4xx/5xx (fire-and-forget)
const { trackResponseTime, trackErrorRate } = require('../metrics');

function metricsMiddleware(req, res, next) {
  const start = process.hrtime.bigint();

  res.on('finish', () => {
    const durationMs = Number(process.hrtime.bigint() - start) / 1e6;
    // baseUrl + route.path agrupa /api/orders/1 e /api/orders/2 na mesma série
    const route = req.route ? `${req.baseUrl}${req.route.path}` : req.path;
    trackResponseTime(Math.round(durationMs), `${req.method} ${route}`).catch(() => {});
    trackErrorRate(res.statusCode).catch(() => {});
  });

  next();
}

module.exports = metricsMiddleware;
