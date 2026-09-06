#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q108-40-service-add-second-selector-key-fix${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Service 'payment-worker-svc' selector requires both app=payment-worker and tier=backend" \
  bash -c "[ \"\$(kubectl get service payment-worker-svc -n '$QUESTION_ID' -o jsonpath='{.spec.selector.app}')\" = 'payment-worker' ] && \
    [ \"\$(kubectl get service payment-worker-svc -n '$QUESTION_ID' -o jsonpath='{.spec.selector.tier}')\" = 'backend' ]"

check_criterion "Service 'payment-worker-svc' has exactly 2 ready endpoints (stable only, canary excluded)" \
  bash -c '
    for _ in $(seq 1 15); do
      count="$(kubectl get endpoints payment-worker-svc -n "'"$QUESTION_ID"'" -o jsonpath="{.subsets[*].addresses[*].ip}" 2>/dev/null | wc -w | tr -d " ")"
      [ "$count" = "2" ] && exit 0
      sleep 2
    done
    exit 1
  '

print_score
