#!/usr/bin/env node
// migrations/cli.js — node migrations/cli.js up | down <versão> | status
const { Pool } = require('pg');
const MigrationRunner = require('./runner');

const pool = new Pool({
  connectionString: process.env.DATABASE_URL || 'postgresql://postgres:postgres@localhost:5432/technova'
});

const [command, arg] = process.argv.slice(2);
let runner;

async function printStatus() {
  const rows = await runner.status();
  console.table(rows.map(r => ({
    versão: r.version,
    estado: r.state,
    descrição: r.description,
    aplicada_em: r.applied_at ? r.applied_at.toISOString() : '-',
    revertida_em: r.rolled_back_at ? r.rolled_back_at.toISOString() : '-'
  })));
  const orders = await pool.query('SELECT COUNT(*)::int AS n FROM orders;');
  const cols = await pool.query(`
    SELECT string_agg(column_name, ', ' ORDER BY ordinal_position) AS c
      FROM information_schema.columns WHERE table_name = 'orders';
  `);
  console.log(`orders: ${orders.rows[0].n} linhas | colunas: ${cols.rows[0].c}`);
}

(async () => {
  // Conexão dedicada: BEGIN/COMMIT precisam cair na MESMA conexão (o Pool alterna entre várias)
  const client = await pool.connect();
  runner = new MigrationRunner(client);
  try {
    switch (command) {
    case 'up': {
      const done = await runner.migrate();
      console.log(done.length ? `✅ Migrações aplicadas: ${done.join(', ')}` : '✅ Nada pendente');
      await printStatus();
      break;
    }
    case 'down': {
      if (!arg) {
        console.error('Uso: node migrations/cli.js down <versão>');
        console.error('  down 001  → reverte tudo acima da 001 (mantém a 001)');
        console.error('  down 000  → reverte todas');
        process.exitCode = 1;
        break;
      }
      const done = await runner.rollback(arg);
      console.log(done.length ? `✅ Revertidas: ${done.join(', ')} (alvo ${arg})` : `✅ Nada acima de ${arg}`);
      await printStatus();
      break;
    }
    case 'status':
      await printStatus();
      break;
    default:
      console.log('Uso: node migrations/cli.js [up|down <versão>|status]');
    }
  } catch (error) {
    console.error('❌ Erro:', error.message);
    process.exitCode = 1;
  } finally {
    client.release();
    await pool.end();
  }
})();
