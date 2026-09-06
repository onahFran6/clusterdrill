#!/usr/bin/env bash
# No "set -e" - a failed criterion is a normal result, not a script error.
set -uo pipefail

QUESTION_ID="q104-39-set-resources-triggers-rollout${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Container 'image-worker' requests cpu=100m, memory=100Mi" \
  bash -c '
    cpu="$(kubectl get deployment image-worker -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.containers[0].resources.requests.cpu}" 2>/dev/null)"
    mem="$(kubectl get deployment image-worker -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.containers[0].resources.requests.memory}" 2>/dev/null)"
    [ "$cpu" = "100m" ] && [ "$mem" = "100Mi" ]
  '

check_criterion "Container 'image-worker' limits cpu=200m, memory=200Mi, and the rollout completed (2 ready, 2 updated)" \
  bash -c '
    cpu="$(kubectl get deployment image-worker -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.containers[0].resources.limits.cpu}" 2>/dev/null)"
    mem="$(kubectl get deployment image-worker -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.containers[0].resources.limits.memory}" 2>/dev/null)"
    ready="$(kubectl get deployment image-worker -n "'"$QUESTION_ID"'" -o jsonpath="{.status.readyReplicas}" 2>/dev/null)"
    updated="$(kubectl get deployment image-worker -n "'"$QUESTION_ID"'" -o jsonpath="{.status.updatedReplicas}" 2>/dev/null)"
    [ "$cpu" = "200m" ] && [ "$mem" = "200Mi" ] && [ "$ready" = "2" ] && [ "$updated" = "2" ]
  '

print_score
