// src/metrics.js
// Emite métricas customizadas para o CloudWatch (namespace TechNova/API)
//
// Na EC2 as credenciais vêm do LabInstanceProfile (LabRole), sem chave no container.
// Fora da AWS (dev local, testes) a emissão fica desligada: METRICS_ENABLED=true liga.

const NAMESPACE = 'TechNova/API';
const enabled = process.env.METRICS_ENABLED === 'true';

let client = null;
let PutMetricDataCommand = null;
if (enabled) {
  const sdk = require('@aws-sdk/client-cloudwatch');
  PutMetricDataCommand = sdk.PutMetricDataCommand;
  client = new sdk.CloudWatchClient({ region: process.env.AWS_REGION || 'us-east-1' });
}

const environment = () => process.env.NODE_ENV || 'development';

// Cada métrica é publicada duas vezes: só com Environment (é a série que os alarmes
// observam) e, quando há dimensão extra, com ela também (para detalhar no console).
async function emitMetric(metricName, value, unit = 'Count', dimensions = []) {
  if (!enabled) return;

  const base = [{ Name: 'Environment', Value: environment() }];
  const data = [{ MetricName: metricName, Value: value, Unit: unit, Timestamp: new Date(), Dimensions: base }];
  if (dimensions.length > 0) {
    data.push({ MetricName: metricName, Value: value, Unit: unit, Timestamp: new Date(), Dimensions: [...base, ...dimensions] });
  }

  try {
    await client.send(new PutMetricDataCommand({ Namespace: NAMESPACE, MetricData: data }));
  } catch (error) {
    // A API nunca cai porque o CloudWatch falhou
    console.warn(`[Metrics] Falha ao emitir ${metricName}: ${error.message}`);
  }
}

const trackOrderCreated = () => emitMetric('OrdersCreated', 1);

const trackOrderFailed = errorType =>
  emitMetric('OrdersFailed', 1, 'Count', [{ Name: 'ErrorType', Value: errorType }]);

const trackResponseTime = (durationMs, endpoint) =>
  emitMetric('ResponseTime', durationMs, 'Milliseconds', [{ Name: 'Endpoint', Value: endpoint }]);

async function trackErrorRate(statusCode) {
  if (statusCode >= 500) await emitMetric('Error5xx', 1);
  else if (statusCode >= 400) await emitMetric('Error4xx', 1);
}

module.exports = {
  NAMESPACE,
  enabled,
  emitMetric,
  trackOrderCreated,
  trackOrderFailed,
  trackResponseTime,
  trackErrorRate
};
