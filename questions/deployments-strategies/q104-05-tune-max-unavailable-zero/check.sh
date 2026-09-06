#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q104-05-tune-max-unavailable-zero${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Deployment 'api-gateway' has maxUnavailable=0 (replicas/image unchanged)" \
  bash -c '
    replicas="$(kubectl get deployment api-gateway -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.replicas}" 2>/dev/null)"
    image="$(kubectl get deployment api-gateway -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.containers[0].image}" 2>/dev/null)"
    maxunavail="$(kubectl get deployment api-gateway -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.strategy.rollingUpdate.maxUnavailable}" 2>/dev/null)"
    [ "$replicas" = "4" ] && [ "$image" = "nginx:1.24-alpine" ] && [ "$maxunavail" = "0" ]
  '

check_criterion "Deployment 'api-gateway' uses RollingUpdate strategy with maxSurge=2" \
  bash -c '
    strategy="$(kubectl get deployment api-gateway -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.strategy.type}" 2>/dev/null)"
    maxsurge="$(kubectl get deployment api-gateway -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.strategy.rollingUpdate.maxSurge}" 2>/dev/null)"
    [ "$strategy" = "RollingUpdate" ] && [ "$maxsurge" = "2" ]
  '

print_score
