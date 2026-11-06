// migrations/002_expand_order_status_enum.js
// FASE EXPAND: cria status_v2 (enum com mais estados) MANTENDO a coluna status original.
//
// Um trigger mantém status_v2 em sincronia com status enquanto as duas versões da API
// convivem: a versão antiga escreve em status e o valor aparece em status_v2.

module.exports = {
  version: '002',
  description: 'Expand: adiciona status_v2 (enum expandido) mantendo status original',

  up: async (db) => {
    await db.query(`
      DO $$ BEGIN
        CREATE TYPE order_status_v2 AS ENUM (
          'pending', 'confirmed', 'processing',
          'shipped', 'delivered', 'cancelled', 'refunded'
        );
      EXCEPTION WHEN duplicate_object THEN NULL;
      END $$;
    `);

    await db.query('ALTER TABLE orders ADD COLUMN IF NOT EXISTS status_v2 order_status_v2;');

    // Backfill: copia o valor antigo para a coluna nova
    const res = await db.query(`
      UPDATE orders SET status_v2 = status::order_status_v2
       WHERE status_v2 IS NULL;
    `);

    // Sincronia status → status_v2 durante a transição
    await db.query(`
      CREATE OR REPLACE FUNCTION orders_sync_status_v2() RETURNS trigger AS $$
      BEGIN
        IF NEW.status_v2 IS NULL OR NEW.status IS DISTINCT FROM OLD.status THEN
          NEW.status_v2 := NEW.status::order_status_v2;
        END IF;
        RETURN NEW;
      END $$ LANGUAGE plpgsql;
    `);
    await db.query('DROP TRIGGER IF EXISTS trg_orders_sync_status_v2 ON orders;');
    await db.query(`
      CREATE TRIGGER trg_orders_sync_status_v2
        BEFORE INSERT OR UPDATE ON orders
        FOR EACH ROW EXECUTE FUNCTION orders_sync_status_v2();
    `);
    console.log(`[Migration 002] UP: status_v2 adicionado (${res.rowCount} linhas copiadas)`);
  },

  down: async (db) => {
    await db.query('DROP TRIGGER IF EXISTS trg_orders_sync_status_v2 ON orders;');
    await db.query('DROP FUNCTION IF EXISTS orders_sync_status_v2();');
    await db.query('ALTER TABLE orders DROP COLUMN IF EXISTS status_v2;');
    await db.query('DROP TYPE IF EXISTS order_status_v2;');
    console.log('[Migration 002] DOWN: status_v2, trigger e tipo removidos');
  },

  verify: async (db) => {
    const col = await db.query(`
      SELECT 1 FROM information_schema.columns
       WHERE table_name = 'orders' AND column_name = 'status_v2';
    `);
    const diverge = await db.query(`
      SELECT COUNT(*)::int AS n FROM orders WHERE status_v2::text IS DISTINCT FROM status;
    `);
    return col.rows.length === 1 && diverge.rows[0].n === 0;
  }
};
