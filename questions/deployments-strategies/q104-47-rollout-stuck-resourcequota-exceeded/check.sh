#!/usr/bin/env bash
# No "set -e" - a failed criterion is a normal result, not a script error.
set -uo pipefail

QUESTION_ID="q104-47-rollout-stuck-resourcequota-exceeded${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Container 'checkout-worker' requests.cpu=200m and limits.cpu=200m, image is busybox:1.36" \
  bash -c '
    req="$(kubectl get deployment checkout-worker -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.containers[0].resources.requests.cpu}" 2>/dev/null)"
    lim="$(kubectl get deployment checkout-worker -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.containers[0].resources.limits.cpu}" 2>/dev/null)"
    image="$(kubectl get deployment checkout-worker -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.containers[0].image}" 2>/dev/null)"
    [ "$req" = "200m" ] && [ "$lim" = "200m" ] && [ "$image" = "busybox:1.36" ]
  '

check_criterion "Deployment 'checkout-worker' rollout completed: 1 ready, 1 updated" \
  bash -c '
    ready="$(kubectl get deployment checkout-worker -n "'"$QUESTION_ID"'" -o jsonpath="{.status.readyReplicas}" 2>/dev/null)"
    updated="$(kubectl get deployment checkout-worker -n "'"$QUESTION_ID"'" -o jsonpath="{.status.updatedReplicas}" 2>/dev/null)"
    [ "$ready" = "1" ] && [ "$updated" = "1" ]
  '

check_criterion "Deployment 'checkout-worker' Progressing condition is True, reason NewReplicaSetAvailable" \
  bash -c '
    status="$(kubectl get deployment checkout-worker -n "'"$QUESTION_ID"'" -o jsonpath="{.status.conditions[?(@.type==\"Progressing\")].status}" 2>/dev/null)"
    reason="$(kubectl get deployment checkout-worker -n "'"$QUESTION_ID"'" -o jsonpath="{.status.conditions[?(@.type==\"Progressing\")].reason}" 2>/dev/null)"
    [ "$status" = "True" ] && [ "$reason" = "NewReplicaSetAvailable" ]
  '

print_score
