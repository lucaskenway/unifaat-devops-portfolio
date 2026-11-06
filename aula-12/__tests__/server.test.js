const request = require('supertest');
const app = require('../server');
const featureFlags = require('../src/feature-flags');
const { FeatureFlags } = require('../src/feature-flags');
const { calculateShippingV1, calculateShippingV2 } = require('../routes/orders');

afterEach(() => {
  delete process.env.FF_NEW_SHIPPING_CALC;
  delete process.env.FF_BULK_ORDERS;
  featureFlags.reload();
});

describe('Health e versão', () => {
  it('GET /health retorna 200 e status ok', async () => {
    const res = await request(app).get('/health');
    expect(res.statusCode).toBe(200);
    expect(res.body.status).toBe('ok');
    expect(res.body.version).toBe('1.3.0');
  });

  it('GET /version retorna commit e flags', async () => {
    const res = await request(app).get('/version');
    expect(res.statusCode).toBe(200);
    expect(res.body.commit).toBeDefined();
    expect(res.body.flags).toHaveProperty('new_shipping_calc');
  });
});

describe('FeatureFlags', () => {
  it('lê variáveis FF_* e normaliza o nome', () => {
    const ff = new FeatureFlags({ NODE_ENV: 'test', FF_NEW_CHECKOUT: 'true', FF_BULK_ORDERS: 'false' });
    expect(ff.isEnabled('new_checkout')).toBe(true);
    expect(ff.isEnabled('NEW_CHECKOUT')).toBe(true);
    expect(ff.isEnabled('bulk_orders')).toBe(false);
  });

  it('usa os padrões quando a variável não existe', () => {
    const ff = new FeatureFlags({ NODE_ENV: 'test' });
    expect(ff.isEnabled('new_shipping_calc')).toBe(true);
    expect(ff.isEnabled('ai_recommendations')).toBe(false);
  });

  it('flag desconhecida é sempre desligada', () => {
    const ff = new FeatureFlags({ NODE_ENV: 'test' });
    expect(ff.isEnabled('nao_existe')).toBe(false);
  });
});

describe('Endpoint /flags', () => {
  it('lista as flags fora de produção', async () => {
    const res = await request(app).get('/flags');
    expect(res.statusCode).toBe(200);
    expect(res.body.flags).toHaveProperty('bulk_orders');
  });

  it('reload relê o ambiente', async () => {
    process.env.FF_BULK_ORDERS = 'true';
    const res = await request(app).post('/flags/reload');
    expect(res.body.flags.bulk_orders).toBe(true);
  });

  it('é bloqueado em produção (403)', async () => {
    const original = process.env.NODE_ENV;
    process.env.NODE_ENV = 'production';
    try {
      const res = await request(app).get('/flags');
      expect(res.statusCode).toBe(403);
    } finally {
      process.env.NODE_ENV = original;
    }
  });
});

describe('Frete controlado por feature flag', () => {
  const body = { customer_id: '123', items: [{ name: 'Widget', price: 29.9, weight: 0.3 }] };

  it('cálculos de frete', () => {
    expect(calculateShippingV1()).toBe(10);
    expect(calculateShippingV2([{ weight: 4 }])).toBe(14);
    expect(calculateShippingV2([{ weight: 0.3 }])).toBe(5); // mínimo
  });

  it('flag ligada → frete v2 (por peso)', async () => {
    process.env.FF_NEW_SHIPPING_CALC = 'true';
    featureFlags.reload();
    const res = await request(app).post('/api/orders').send(body);
    expect(res.statusCode).toBe(201);
    expect(res.body.shippingMethod).toBe('v2-peso');
    expect(res.body.shipping).toBe(5);
  });

  it('flag desligada → frete legado (R$ 10) sem redeploy', async () => {
    process.env.FF_NEW_SHIPPING_CALC = 'false';
    featureFlags.reload();
    const res = await request(app).post('/api/orders').send(body);
    expect(res.body.shippingMethod).toBe('v1-fixo');
    expect(res.body.shipping).toBe(10);
    expect(res.body.total).toBe(39.9);
  });

  it('bulk_orders dá 10% de desconto com 10+ itens', async () => {
    process.env.FF_BULK_ORDERS = 'true';
    featureFlags.reload();
    const res = await request(app).post('/api/orders')
      .send({ items: [{ name: 'Cabo', price: 10, quantity: 10 }] });
    expect(res.body.discount).toBe(10);
  });
});

describe('Orders API', () => {
  it('GET /api/orders retorna array', async () => {
    const res = await request(app).get('/api/orders');
    expect(res.statusCode).toBe(200);
    expect(Array.isArray(res.body)).toBe(true);
  });

  it('GET /api/orders/:id inexistente retorna 404', async () => {
    const res = await request(app).get('/api/orders/9999');
    expect(res.statusCode).toBe(404);
  });

  it('POST no formato legado continua aceito', async () => {
    const res = await request(app).post('/api/orders').send({ product: 'Mouse', quantity: 2 });
    expect(res.statusCode).toBe(201);
    expect(res.body.quantity).toBe(2);
  });

  it('POST sem dados retorna 400', async () => {
    const res = await request(app).post('/api/orders').send({});
    expect(res.statusCode).toBe(400);
  });
});
