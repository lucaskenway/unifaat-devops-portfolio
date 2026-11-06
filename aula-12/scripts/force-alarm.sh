#!/bin/bash
# scripts/force-alarm.sh — teste de ponta a ponta do AIOps sem depender da API:
# publica ResponseTime alto e Error5xx em TechNova/API (Environment=production) por N
# minutos. Isso leva TechNova-HighLatency e TechNova-HighError5xx (e o composto) para
# ALARM; o EventBridge então invoca a Lambda TechNovaAIOpsAnalyzer.
# Uso: bash scripts/force-alarm.sh [minutos=5]
set -euo pipefail
MIN=${1:-5}
for i in $(seq 1 $((MIN * 2))); do
  aws cloudwatch put-metric-data --namespace TechNova/API --metric-data \
    "MetricName=ResponseTime,Value=2200,Unit=Milliseconds,Dimensions=[{Name=Environment,Value=production}]" \
    "MetricName=Error5xx,Value=8,Unit=Count,Dimensions=[{Name=Environment,Value=production}]"
  echo "$(date -u +%H:%M:%S) ponto $i/$((MIN * 2)): ResponseTime=2200ms Error5xx=+8"
  sleep 30
done
aws cloudwatch describe-alarms --alarm-name-prefix TechNova- \
  --query '[MetricAlarms[].[AlarmName,StateValue], CompositeAlarms[].[AlarmName,StateValue]]' --output text
