#!/usr/bin/env bash
# Operação do Blue/Green da Aula 11 — usado pelo workflow deploy-blue-green.yml e
# também à mão (ver ../ROLLBACK.md). Descobre tudo pelos nomes/tags que o Terraform
# cria, então não precisa do state nem dos outputs.
#
# Uso:
#   bluegreen.sh status                  ambiente ativo, ARNs e saúde dos targets
#   bluegreen.sh idle                    cor e IP público do ambiente ocioso (key=value)
#   bluegreen.sh wait-healthy <cor>      espera o Target Group da cor ficar healthy
#   bluegreen.sh switch <cor>            aponta o listener HTTP:80 para a cor
#   bluegreen.sh validate <cor> [sha]    valida o ALB depois do switch
#   bluegreen.sh rollback                volta o listener para a outra cor
#
# Variáveis (com padrão para o RA 6325226): ALB_NAME, TG_PREFIX, EC2_PREFIX, AWS_REGION,
# VALIDATE_REQUESTS, HEALTHY_TIMEOUT
set -euo pipefail

export AWS_REGION="${AWS_REGION:-us-east-1}"
export AWS_DEFAULT_REGION="$AWS_REGION"
ALB_NAME="${ALB_NAME:-6325226-a11-alb}"
TG_PREFIX="${TG_PREFIX:-6325226-a11}"
EC2_PREFIX="${EC2_PREFIX:-6325226-technova-aula11}"
VALIDATE_REQUESTS="${VALIDATE_REQUESTS:-20}"
STABLE_CHECKS="${STABLE_CHECKS:-10}"   # respostas seguidas da cor nova antes de validar
HEALTHY_TIMEOUT="${HEALTHY_TIMEOUT:-300}"

log() { echo "[$(date -u +%H:%M:%S)] $*" >&2; }
die() { log "ERRO: $*"; exit 1; }

other() { [ "$1" = blue ] && echo green || echo blue; }

check_color() {
  case "${1:-}" in blue|green) ;; *) die "cor inválida: '${1:-}' (use blue ou green)" ;; esac
}

alb_arn() {
  aws elbv2 describe-load-balancers --names "$ALB_NAME" \
    --query 'LoadBalancers[0].LoadBalancerArn' --output text
}

alb_dns() {
  aws elbv2 describe-load-balancers --names "$ALB_NAME" \
    --query 'LoadBalancers[0].DNSName' --output text
}

listener_arn() {
  aws elbv2 describe-listeners --load-balancer-arn "$(alb_arn)" \
    --query 'Listeners[?Port==`80`].ListenerArn | [0]' --output text
}

tg_arn() {
  aws elbv2 describe-target-groups --names "$TG_PREFIX-$1" \
    --query 'TargetGroups[0].TargetGroupArn' --output text
}

active_color() {
  local arn
  arn=$(aws elbv2 describe-listeners --listener-arns "$(listener_arn)" \
    --query 'Listeners[0].DefaultActions[0].TargetGroupArn' --output text)
  case "$arn" in
    "$(tg_arn blue)") echo blue ;;
    "$(tg_arn green)") echo green ;;
    *) die "o listener aponta para um Target Group desconhecido: $arn" ;;
  esac
}

instance_ip() {
  aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=$EC2_PREFIX-$1" "Name=instance-state-name,Values=running" \
    --query 'Reservations[0].Instances[0].PublicIpAddress' --output text
}

target_state() {
  aws elbv2 describe-target-health --target-group-arn "$(tg_arn "$1")" \
    --query 'TargetHealthDescriptions[0].TargetHealth.State' --output text
}

cmd_status() {
  local active
  active=$(active_color)
  echo "ALB:      http://$(alb_dns)"
  echo "Listener: $(listener_arn)"
  for c in blue green; do
    local mark=" "
    [ "$c" = "$active" ] && mark="*"
    printf '%s %-5s  %-9s  ip=%-15s  %s\n' "$mark" "$c" "$(target_state "$c")" "$(instance_ip "$c")" "$(tg_arn "$c")"
  done
  echo "(* = ambiente ativo, recebendo 100% do tráfego)"
}

cmd_idle() {
  local active idle ip
  active=$(active_color)
  idle=$(other "$active")
  ip=$(instance_ip "$idle")
  [ -n "$ip" ] && [ "$ip" != "None" ] || die "EC2 $EC2_PREFIX-$idle não está rodando"
  echo "active=$active"
  echo "idle=$idle"
  echo "idle_ip=$ip"
  echo "alb_dns=$(alb_dns)"
}

cmd_wait_healthy() {
  check_color "$1"
  local start state
  start=$(date +%s)
  while true; do
    state=$(target_state "$1")
    log "target group $1: $state"
    [ "$state" = healthy ] && return 0
    [ $(( $(date +%s) - start )) -ge "$HEALTHY_TIMEOUT" ] && die "$1 não ficou healthy em ${HEALTHY_TIMEOUT}s"
    sleep 5
  done
}

cmd_switch() {
  check_color "$1"
  local from start
  from=$(active_color)
  if [ "$from" = "$1" ]; then
    log "listener já aponta para $1 — nada a fazer"
    return 0
  fi
  start=$(date +%s%N)
  aws elbv2 modify-listener --listener-arn "$(listener_arn)" \
    --default-actions "Type=forward,TargetGroupArn=$(tg_arn "$1")" >/dev/null
  log "🔀 tráfego $from → $1 em $(( ($(date +%s%N) - start) / 1000000 )) ms (chamada à API do ALB)"
}

# Valida pelo DNS do ALB, como um cliente real: /health tem que responder com a cor
# nova, /version com o commit implantado e a API de pedidos tem que responder 200 em
# todas as requisições. Qualquer falha → exit 1 (o workflow então faz o rollback).
cmd_validate() {
  check_color "$1"
  local color="$1" sha="${2:-}" dns body code i fails=0
  dns=$(alb_dns)

  # O modify-listener vale para conexões novas em alguns segundos, e durante a propagação
  # os nós do ALB ainda alternam entre as duas cores. Só segue quando $STABLE_CHECKS
  # respostas SEGUIDAS vierem da cor nova (uma resposta só não prova a troca).
  local streak=0
  for i in $(seq 1 30); do
    body=$(curl -s --max-time 5 "http://$dns/health" || true)
    if echo "$body" | grep -q "\"color\":\"$color\""; then
      streak=$((streak + 1))
      [ "$streak" -ge "$STABLE_CHECKS" ] && break
    else
      [ "$streak" -gt 0 ] && log "ainda há resposta da cor antiga (propagação), recomeçando a contagem"
      streak=0
      log "aguardando o ALB servir só $color ($i/30)..."
      sleep 2
    fi
  done
  [ "$streak" -ge "$STABLE_CHECKS" ] || die "o ALB não está servindo só $color: $body"
  log "✅ ALB servindo $color: $body"

  if [ -n "$sha" ]; then
    body=$(curl -s --max-time 5 "http://$dns/version" || true)
    echo "$body" | grep -q "\"commit\":\"$sha\"" || die "/version não reporta o commit $sha: $body"
    log "✅ /version: $body"
  fi

  for i in $(seq 1 "$VALIDATE_REQUESTS"); do
    code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 "http://$dns/api/orders" || true)
    if [ "$code" != 200 ]; then
      fails=$((fails + 1))
      log "❌ requisição $i/$VALIDATE_REQUESTS em /api/orders: HTTP $code"
    fi
  done
  if [ "$fails" -gt 0 ]; then
    die "$fails/$VALIDATE_REQUESTS requisições falharam em /api/orders (taxa de erro $(( fails * 100 / VALIDATE_REQUESTS ))%)"
  fi
  log "✅ $VALIDATE_REQUESTS/$VALIDATE_REQUESTS requisições OK em /api/orders"
}

cmd_rollback() {
  local from to
  from=$(active_color)
  to=$(other "$from")
  [ "$(target_state "$to")" = healthy ] || log "⚠️  $to não está healthy — o rollback segue mesmo assim"
  log "⏪ rollback: $from → $to"
  cmd_switch "$to"
}

case "${1:-}" in
  status) cmd_status ;;
  idle) cmd_idle ;;
  wait-healthy) cmd_wait_healthy "${2:-}" ;;
  switch) cmd_switch "${2:-}" ;;
  validate) cmd_validate "${2:-}" "${3:-}" ;;
  rollback) cmd_rollback ;;
  *) sed -n '2,15p' "$0"; exit 2 ;;
esac
