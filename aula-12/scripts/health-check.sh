#!/bin/bash
# scripts/health-check.sh — health check com janela de observação
#
# Uso: health-check.sh <host> [porta] [checagens] [intervalo_s] [max_falhas]
# Faz N checagens em /health; passa se o número de falhas for <= max_falhas.
# Um único 200 logo após o deploy não prova nada: a janela pega o container que
# sobe, responde e cai (crash loop) ou que degrada depois de alguns segundos.
set -u
HOST=${1:-localhost}
PORT=${2:-3000}
CHECKS=${3:-6}
INTERVAL=${4:-10}
MAX_FAILURES=${5:-2}
URL="http://${HOST}:${PORT}/health"

echo "🏥 Janela de observação: ${CHECKS} checagens a cada ${INTERVAL}s em ${URL} (tolerância: ${MAX_FAILURES} falhas)"
FAILURES=0
for i in $(seq 1 "$CHECKS"); do
  CODE=$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 "$URL" || true)
  if [ "$CODE" = "200" ]; then
    echo "  ✅ check $i/$CHECKS: HTTP $CODE"
  else
    FAILURES=$((FAILURES + 1))
    echo "  ❌ check $i/$CHECKS: HTTP ${CODE:-000}"
  fi
  [ "$i" -lt "$CHECKS" ] && sleep "$INTERVAL"
done

echo "Resultado: ${FAILURES}/${CHECKS} falhas"
if [ "$FAILURES" -gt "$MAX_FAILURES" ]; then
  echo "❌ Health check FAILED"
  exit 1
fi
echo "✅ Health check PASSED"
curl -s --max-time 5 "$URL"; echo
