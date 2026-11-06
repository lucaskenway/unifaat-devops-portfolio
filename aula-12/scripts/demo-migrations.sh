#!/bin/bash
# scripts/demo-migrations.sh — roda NA EC2 (ou em qualquer host com Docker):
# sobe um Postgres de teste com db/init.sql e exercita up / down / status do CLI,
# conferindo que nenhuma linha de orders se perde no caminho.
# Uso: cd aula-12 && bash scripts/demo-migrations.sh
set -euo pipefail
NET=technova-db
DB_URL=postgresql://postgres:postgres@technova-postgres:5432/technova

cli() {
  echo; echo "\$ node migrations/cli.js $*"
  docker run --rm --network "$NET" -v "$PWD:/w" -w /w -e DATABASE_URL="$DB_URL" \
    node:20-alpine node migrations/cli.js "$@"
}
psql_() { docker exec technova-postgres psql -U postgres -d technova -c "$1"; }

cli status
cli up
psql_ "SELECT id, customer_name, customer_email, status, status_v2 FROM orders ORDER BY id;"
cli down 001
cli down 000
psql_ "SELECT id, customer_name, status FROM orders ORDER BY id;"
cli up
