// routes/flags.js
// Inspeção das feature flags. Fica DESLIGADO em produção: expor quais features
// existem (e quais estão desligadas) ajuda quem quer explorar a API.
const express = require('express');
const featureFlags = require('../src/feature-flags');

const router = express.Router();

function blockInProduction(req, res, next) {
  if (process.env.NODE_ENV === 'production') {
    return res.status(403).json({ error: 'Endpoint desabilitado em produção' });
  }
  next();
}

router.use(blockInProduction);

// GET /flags — estado atual das flags
router.get('/', (req, res) => {
  res.json({ flags: featureFlags.getAllFlags(), loadedAt: featureFlags.loadedAt });
});

// POST /flags/reload — relê as variáveis FF_* do processo
router.post('/reload', (req, res) => {
  featureFlags.reload();
  res.json({ message: 'Flags recarregadas', flags: featureFlags.getAllFlags() });
});

module.exports = router;
