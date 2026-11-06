// Testa a lógica do runner com um "banco" falso que registra as queries
const fs = require('fs');
const os = require('os');
const path = require('path');
const MigrationRunner = require('../migrations/runner');

function fakeDb() {
  const state = { rows: {}, log: [] };
  return {
    state,
    async query(sql, params = []) {
      const s = sql.replace(/\s+/g, ' ').trim();
      state.log.push(s.split(' ')[0]);
      if (s.startsWith('SELECT version FROM schema_migrations')) {
        return { rows: Object.values(state.rows).filter(r => !r.rolled_back_at).sort((a, b) => a.version.localeCompare(b.version)) };
      }
      if (s.startsWith('INSERT INTO schema_migrations')) {
        state.rows[params[0]] = { version: params[0], rolled_back_at: null };
      }
      if (s.startsWith('UPDATE schema_migrations')) {
        state.rows[params[0]].rolled_back_at = new Date();
      }
      return { rows: [], rowCount: 0 };
    }
  };
}

function migrationsDir(verifyResult = true) {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'mig-'));
  for (const v of ['001', '002']) {
    fs.writeFileSync(path.join(dir, `${v}_teste.js`), `
      module.exports = { version: '${v}', description: 'teste ${v}',
        up: async (db) => db.query('UP ${v}'),
        down: async (db) => db.query('DOWN ${v}'),
        verify: async () => ${verifyResult} };`);
  }
  return dir;
}

describe('MigrationRunner', () => {
  it('aplica as pendentes em ordem e registra', async () => {
    const db = fakeDb();
    const runner = new MigrationRunner(db, migrationsDir());
    expect(await runner.migrate()).toEqual(['001', '002']);
    expect(await runner.getAppliedMigrations()).toEqual(['001', '002']);
    expect(await runner.migrate()).toEqual([]);
  });

  it('reverte em ordem decrescente até o alvo e permite reaplicar', async () => {
    const db = fakeDb();
    const runner = new MigrationRunner(db, migrationsDir());
    await runner.migrate();
    expect(await runner.rollback('001')).toEqual(['002']);
    expect(await runner.getAppliedMigrations()).toEqual(['001']);
    expect(await runner.rollback('000')).toEqual(['001']);
    expect(await runner.getAppliedMigrations()).toEqual([]);
    expect(await runner.migrate()).toEqual(['001', '002']);
  });

  it('verify falso desfaz a transação', async () => {
    const db = fakeDb();
    const runner = new MigrationRunner(db, migrationsDir(false));
    await expect(runner.migrate()).rejects.toThrow('verify da migração 001 falhou');
    expect(db.state.log).toContain('ROLLBACK');
  });
});
