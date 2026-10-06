#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q111-11-recreate-strategy-no-overlap${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Strategy type is Recreate with no rollingUpdate block" \
  bash -c '
    type="$(kubectl get deployment ledger -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.strategy.type}" 2>/dev/null)"
    ru="$(kubectl get deployment ledger -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.strategy.rollingUpdate}" 2>/dev/null)"
    [ "$type" = "Recreate" ] && [ -z "$ru" ]
  '

check_criterion "Deployment runs image redis:7.4-alpine, 2/2 ready" \
  bash -c '
    image="$(kubectl get deployment ledger -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.containers[0].image}" 2>/dev/null)"
    ready="$(kubectl get deployment ledger -n "'"$QUESTION_ID"'" -o jsonpath="{.status.readyReplicas}" 2>/dev/null)"
    [ "$image" = "redis:7.4-alpine" ] && [ "$ready" = "2" ]
  '

print_score
