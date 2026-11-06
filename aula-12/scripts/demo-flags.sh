#!/bin/bash
# scripts/demo-flags.sh — demonstra o "rollback" de uma feature só com flag + restart
# (mesmo código, nenhuma imagem nova). Roda local: cd aula-12 && bash scripts/demo-flags.sh
set -u
PORT=${PORT:-3100}
BODY='{"customer_id":"123","items":[{"name":"Widget","price":29.90,"weight":0.3}]}'

start() {
  FF_NEW_SHIPPING_CALC=$1 NODE_ENV=development PORT=$PORT node server.js > /tmp/technova-demo.log 2>&1 &
  PID=$!
  for _ in $(seq 1 30); do curl -sf "localhost:$PORT/health" >/dev/null && return; sleep 0.5; done
}
show() {
  echo "\$ curl localhost:$PORT/flags"; curl -s "localhost:$PORT/flags"; echo
  echo "\$ curl -X POST localhost:$PORT/api/orders -d '$BODY'"
  curl -s -X POST "localhost:$PORT/api/orders" -H 'Content-Type: application/json' -d "$BODY" \
    | node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>{const o=JSON.parse(s);console.log(JSON.stringify({shippingMethod:o.shippingMethod,shipping:o.shipping,subtotal:o.subtotal,total:o.total}))})'
}

echo "=== 1) FF_NEW_SHIPPING_CALC=true — frete novo (por peso) ==="
start true; show; kill $PID; wait $PID 2>/dev/null || true

echo; echo "=== 2) Problema no frete novo → desliga a flag e reinicia (sem redeploy) ==="
start false; show; kill $PID; wait $PID 2>/dev/null || true
