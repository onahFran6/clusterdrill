#!/usr/bin/env bash
# No "set -e" - a failed criterion is a normal result, not a script error.
set -uo pipefail

QUESTION_ID="q104-20-recreate-strategy-downtime${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Deployment 'billing-worker' exists with Recreate strategy, no rollingUpdate fields, replicas=4, image busybox:1.36" \
  bash -c '
    strategy="$(kubectl get deployment billing-worker -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.strategy.type}" 2>/dev/null)"
    rollingupdate="$(kubectl get deployment billing-worker -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.strategy.rollingUpdate}" 2>/dev/null)"
    replicas="$(kubectl get deployment billing-worker -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.replicas}" 2>/dev/null)"
    image="$(kubectl get deployment billing-worker -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.containers[0].image}" 2>/dev/null)"
    [ "$strategy" = "Recreate" ] && [ -z "$rollingupdate" ] && [ "$replicas" = "4" ] && [ "$image" = "busybox:1.36" ]
  '

print_score
