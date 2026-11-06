// routes/orders.js
// API de pedidos com o cálculo de frete controlado por feature flag
const express = require('express');
const featureFlags = require('../src/feature-flags');
const { trackOrderCreated, trackOrderFailed } = require('../src/metrics');

const router = express.Router();

const orders = [
  { id: 1, product: 'Notebook TechNova Pro', quantity: 2, status: 'pending' },
  { id: 2, product: 'Monitor UltraWide 34"', quantity: 1, status: 'shipped' },
  { id: 3, product: 'Teclado Mecânico RGB', quantity: 5, status: 'delivered' }
];

const round2 = n => Math.round(n * 100) / 100;

// Frete legado: R$ 10,00 fixo por pedido
function calculateShippingV1() {
  return 10.0;
}

// Frete novo: R$ 3,50 por kg (0,5 kg por item sem peso informado), mínimo de R$ 5,00
function calculateShippingV2(items) {
  const totalWeight = items.reduce(
    (sum, item) => sum + (item.weight || 0.5) * (item.quantity || 1),
    0
  );
  return round2(Math.max(5.0, totalWeight * 3.5));
}

// Desconto de 10% para pedidos com 10 itens ou mais (flag bulk_orders)
function calculateBulkDiscount(subtotal) {
  return round2(subtotal * 0.1);
}

// Aceita o formato novo ({ items: [...] }) e o legado ({ product, quantity })
function normalizeItems(body) {
  if (Array.isArray(body.items) && body.items.length > 0) {
    return body.items;
  }
  if (body.product && body.quantity) {
    return [{ name: body.product, quantity: Number(body.quantity), price: Number(body.price) || 0 }];
  }
  return null;
}

router.get('/', (req, res) => {
  res.json(orders);
});

router.get('/:id', (req, res) => {
  const order = orders.find(o => o.id === parseInt(req.params.id, 10));
  if (!order) {
    return res.status(404).json({ error: 'Order not found' });
  }
  res.json(order);
});

router.post('/', (req, res) => {
  const items = normalizeItems(req.body || {});
  if (!items) {
    trackOrderFailed('validation');
    return res.status(400).json({ error: 'Envie items[] ou product e quantity' });
  }

  const newShipping = featureFlags.isEnabled('new_shipping_calc');
  const shipping = newShipping ? calculateShippingV2(items) : calculateShippingV1(items);

  const itemCount = items.reduce((sum, item) => sum + (item.quantity || 1), 0);
  const subtotal = round2(items.reduce((sum, item) => sum + (item.price || 0) * (item.quantity || 1), 0));

  let discount = 0;
  if (featureFlags.isEnabled('bulk_orders') && itemCount >= 10) {
    discount = calculateBulkDiscount(subtotal);
  }

  const order = {
    id: orders.length + 1,
    product: items[0].name,
    quantity: itemCount,
    customer_id: req.body.customer_id || null,
    items,
    subtotal,
    shipping,
    shippingMethod: newShipping ? 'v2-peso' : 'v1-fixo',
    discount,
    total: round2(subtotal + shipping - discount),
    status: 'pending',
    created_at: new Date().toISOString()
  };
  orders.push(order);
  trackOrderCreated();
  res.status(201).json(order);
});

module.exports = router;
module.exports.calculateShippingV1 = calculateShippingV1;
module.exports.calculateShippingV2 = calculateShippingV2;
