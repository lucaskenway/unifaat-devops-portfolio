#!/bin/bash
# aula-11/scripts/log-run.sh <run_id> — trecho relevante do log do job Blue/Green de um run
# (estado, deploy no ocioso, health check do TG, switch, validação e rollback)
set -euo pipefail
RUN=$1
REPO=${REPO:-lucaskenway/unifaat-devops-portfolio}
JOB=$(gh run view "$RUN" -R "$REPO" --json jobs -q '.jobs[] | select(.name | startswith("Blue/Green")) | .databaseId')
echo "===== run $RUN ($(gh run view "$RUN" -R "$REPO" --json event,conclusion -q '"\(.event) → \(.conclusion)"')) ====="
gh api "repos/$REPO/actions/jobs/$JOB/logs" \
  | sed 's/^[0-9T:.-]*Z //' \
  | grep -E '^\[[0-9:]{8}\] ' \
  | grep -vE 'requisição ([2-9]|1[0-9]|20)/|aguardando|: (initial|unused)$'
