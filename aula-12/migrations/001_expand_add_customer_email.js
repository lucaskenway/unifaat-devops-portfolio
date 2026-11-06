// migrations/001_expand_add_customer_email.js
// FASE EXPAND: adiciona orders.customer_email SEM remover customer_name.
//
// A versão antiga da API continua lendo customer_name; a nova pode ler customer_email.
// As duas convivem, então reverter o deploy da API não exige reverter o banco.
// O CONTRACT (remover customer_name) só entra numa migração futura, depois que
// nenhuma versão em produção depender mais da coluna antiga.

module.exports = {
  version: '001',
  description: 'Expand: adiciona customer_email em orders (mantém customer_name)',

  up: async (db) => {
    await db.query('ALTER TABLE orders ADD COLUMN IF NOT EXISTS customer_email VARCHAR(255);');

    // Backfill a partir de customers (tabela existe no schema base db/init.sql)
    const res = await db.query(`
      UPDATE orders o
         SET customer_email = c.email
        FROM customers c
       WHERE o.customer_id = c.id
         AND o.customer_email IS NULL;
    `);
    console.log(`[Migration 001] UP: customer_email adicionada (${res.rowCount} linhas preenchidas)`);
  },

  // Remove só o que a fase expand criou: customer_name e as linhas ficam intactas
  down: async (db) => {
    await db.query('ALTER TABLE orders DROP COLUMN IF EXISTS customer_email;');
    console.log('[Migration 001] DOWN: customer_email removida');
  },

  verify: async (db) => {
    const col = await db.query(`
      SELECT 1 FROM information_schema.columns
       WHERE table_name = 'orders' AND column_name = 'customer_email';
    `);
    const missing = await db.query(`
      SELECT COUNT(*)::int AS n FROM orders
       WHERE customer_id IS NOT NULL AND customer_email IS NULL;
    `);
    return col.rows.length === 1 && missing.rows[0].n === 0;
  }
};
