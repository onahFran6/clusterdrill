#!/usr/bin/env bash
# No "set -e" - a failed criterion is a normal result, not a script error.
set -uo pipefail

QUESTION_ID="q104-46-rollout-stuck-imagepullbackoff-typo${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Deployment 'auth-service' image is redis:7.2-alpine and both replicas ready/updated" \
  bash -c '
    image="$(kubectl get deployment auth-service -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.containers[0].image}" 2>/dev/null)"
    [ "$image" = "redis:7.2-alpine" ] || exit 1
    ready="$(kubectl get deployment auth-service -n "'"$QUESTION_ID"'" -o jsonpath="{.status.readyReplicas}" 2>/dev/null)"
    updated="$(kubectl get deployment auth-service -n "'"$QUESTION_ID"'" -o jsonpath="{.status.updatedReplicas}" 2>/dev/null)"
    [ "$ready" = "2" ] && [ "$updated" = "2" ]
  '

check_criterion "Deployment 'auth-service' rollout genuinely completed (Progressing condition is True, reason NewReplicaSetAvailable)" \
  bash -c '
    status="$(kubectl get deployment auth-service -n "'"$QUESTION_ID"'" -o jsonpath="{.status.conditions[?(@.type==\"Progressing\")].status}" 2>/dev/null)"
    reason="$(kubectl get deployment auth-service -n "'"$QUESTION_ID"'" -o jsonpath="{.status.conditions[?(@.type==\"Progressing\")].reason}" 2>/dev/null)"
    [ "$status" = "True" ] && [ "$reason" = "NewReplicaSetAvailable" ]
  '

print_score
