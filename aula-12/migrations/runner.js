// migrations/runner.js
// Runner de migrações com histórico em schema_migrations.
// Cada migração (e cada rollback) roda numa transação: se falhar no meio, nada fica pela metade.
const fs = require('fs');
const path = require('path');

const FILE_PATTERN = /^(\d{3})_.*\.js$/;

class MigrationRunner {
  constructor(db, migrationsDir = __dirname) {
    this.db = db;
    this.migrationsDir = migrationsDir;
  }

  loadMigrations() {
    return fs.readdirSync(this.migrationsDir)
      .filter(f => FILE_PATTERN.test(f))
      .sort()
      .map(f => require(path.join(this.migrationsDir, f)));
  }

  async ensureMigrationsTable() {
    await this.db.query(`
      CREATE TABLE IF NOT EXISTS schema_migrations (
        version        VARCHAR(10) PRIMARY KEY,
        description    TEXT,
        applied_at     TIMESTAMP DEFAULT NOW(),
        rolled_back_at TIMESTAMP
      );
    `);
  }

  async getAppliedMigrations() {
    await this.ensureMigrationsTable();
    const result = await this.db.query(`
      SELECT version FROM schema_migrations
       WHERE rolled_back_at IS NULL
       ORDER BY version;
    `);
    return result.rows.map(r => r.version);
  }

  async status() {
    await this.ensureMigrationsTable();
    const rows = (await this.db.query(
      'SELECT version, applied_at, rolled_back_at FROM schema_migrations ORDER BY version;'
    )).rows;
    const byVersion = Object.fromEntries(rows.map(r => [r.version, r]));
    return this.loadMigrations().map(m => {
      const row = byVersion[m.version];
      let state = 'pendente';
      if (row && !row.rolled_back_at) state = 'aplicada';
      else if (row && row.rolled_back_at) state = 'revertida';
      return {
        version: m.version,
        state,
        description: m.description,
        applied_at: row ? row.applied_at : null,
        rolled_back_at: row ? row.rolled_back_at : null
      };
    });
  }

  async inTransaction(fn) {
    await this.db.query('BEGIN');
    try {
      await fn();
      await this.db.query('COMMIT');
    } catch (error) {
      await this.db.query('ROLLBACK');
      throw error;
    }
  }

  async migrate() {
    const applied = await this.getAppliedMigrations();
    const done = [];

    for (const migration of this.loadMigrations()) {
      if (applied.includes(migration.version)) continue;
      console.log(`[Migrate] Aplicando ${migration.version}: ${migration.description}`);

      await this.inTransaction(async () => {
        await migration.up(this.db);
        // Upsert: uma migração revertida antes pode ser reaplicada
        await this.db.query(`
          INSERT INTO schema_migrations (version, description, applied_at, rolled_back_at)
          VALUES ($1, $2, NOW(), NULL)
          ON CONFLICT (version) DO UPDATE
            SET description = EXCLUDED.description, applied_at = NOW(), rolled_back_at = NULL;
        `, [migration.version, migration.description]);

        // verify dentro da transação: se a migração não deixou o banco no estado
        // esperado, o ROLLBACK desfaz tudo
        if (migration.verify && !(await migration.verify(this.db))) {
          throw new Error(`verify da migração ${migration.version} falhou`);
        }
      }).catch(error => {
        throw new Error(`Migration ${migration.version} falhou: ${error.message}`);
      });

      console.log(`[Migrate] ${migration.version} aplicada e verificada ✅`);
      done.push(migration.version);
    }
    return done;
  }

  // Reverte, em ordem decrescente, todas as migrações com versão > targetVersion
  async rollback(targetVersion) {
    const applied = await this.getAppliedMigrations();
    const migrations = Object.fromEntries(this.loadMigrations().map(m => [m.version, m]));
    const toRollback = applied.filter(v => v > targetVersion).reverse();
    const done = [];

    for (const version of toRollback) {
      const migration = migrations[version];
      if (!migration) throw new Error(`Arquivo da migração ${version} não encontrado`);
      console.log(`[Rollback] Revertendo ${version}: ${migration.description}`);

      await this.inTransaction(async () => {
        await migration.down(this.db);
        await this.db.query(
          'UPDATE schema_migrations SET rolled_back_at = NOW() WHERE version = $1;',
          [version]
        );
      }).catch(error => {
        throw new Error(`Rollback ${version} falhou: ${error.message}`);
      });

      console.log(`[Rollback] ${version} revertida ✅`);
      done.push(version);
    }
    return done;
  }
}

module.exports = MigrationRunner;
