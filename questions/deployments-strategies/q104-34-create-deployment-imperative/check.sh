#!/usr/bin/env bash
# No "set -e" - a failed criterion is a normal result, not a script error.
set -uo pipefail

QUESTION_ID="q104-34-create-deployment-imperative${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Deployment 'frontend' exists with 3 replicas configured and 3 ready" \
  bash -c '
    replicas="$(kubectl get deployment frontend -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.replicas}" 2>/dev/null)"
    ready="$(kubectl get deployment frontend -n "'"$QUESTION_ID"'" -o jsonpath="{.status.readyReplicas}" 2>/dev/null)"
    [ "$replicas" = "3" ] && [ "$ready" = "3" ]
  '

check_criterion "Deployment 'frontend' runs image nginx:1.25-alpine" \
  [ "$(kget deployment frontend '{.spec.template.spec.containers[0].image}' -n "$QUESTION_ID")" = "nginx:1.25-alpine" ]

print_score
