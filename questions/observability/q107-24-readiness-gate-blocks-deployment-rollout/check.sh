#!/usr/bin/env bash
# No "set -e" - a failed criterion is a normal result, not a script error.
set -uo pipefail

QUESTION_ID="q107-24-readiness-gate-blocks-deployment-rollout${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Deployment 'checkout-api' pod template image is nginx:1.25-alpine (fixed forward, not reverted)" \
  [ "$(kget deployment checkout-api '{.spec.template.spec.containers[0].image}' -n "$QUESTION_ID")" = "nginx:1.25-alpine" ]

check_criterion "Deployment 'checkout-api' has 3 updatedReplicas" \
  [ "$(kget deployment checkout-api '{.status.updatedReplicas}' -n "$QUESTION_ID")" = "3" ]

check_criterion "Deployment 'checkout-api' has 3 readyReplicas" \
  [ "$(kget deployment checkout-api '{.status.readyReplicas}' -n "$QUESTION_ID")" = "3" ]

check_criterion "Deployment 'checkout-api' has 3 availableReplicas" \
  [ "$(kget deployment checkout-api '{.status.availableReplicas}' -n "$QUESTION_ID")" = "3" ]

check_criterion "The ReplicaSet running nginx:1.25-alpine has 3 ready pods (healthy RS holds all replicas)" \
  [ "$(kubectl get rs -n "$QUESTION_ID" -o jsonpath='{.items[?(@.spec.template.spec.containers[0].image=="nginx:1.25-alpine")].status.readyReplicas}' 2>/dev/null)" = "3" ]

print_score
