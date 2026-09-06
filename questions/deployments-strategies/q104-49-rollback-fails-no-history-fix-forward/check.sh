#!/usr/bin/env bash
# No "set -e" - a failed criterion is a normal result, not a script error.
set -uo pipefail

QUESTION_ID="q104-49-rollback-fails-no-history-fix-forward${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Deployment 'pricing-sync' image is alpine:3.19 and both replicas ready/updated" \
  bash -c '
    image="$(kubectl get deployment pricing-sync -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.containers[0].image}" 2>/dev/null)"
    [ "$image" = "alpine:3.19" ] || exit 1
    ready="$(kubectl get deployment pricing-sync -n "'"$QUESTION_ID"'" -o jsonpath="{.status.readyReplicas}" 2>/dev/null)"
    updated="$(kubectl get deployment pricing-sync -n "'"$QUESTION_ID"'" -o jsonpath="{.status.updatedReplicas}" 2>/dev/null)"
    [ "$ready" = "2" ] && [ "$updated" = "2" ]
  '

check_criterion "Deployment 'pricing-sync' Progressing condition is True, reason NewReplicaSetAvailable" \
  bash -c '
    status="$(kubectl get deployment pricing-sync -n "'"$QUESTION_ID"'" -o jsonpath="{.status.conditions[?(@.type==\"Progressing\")].status}" 2>/dev/null)"
    reason="$(kubectl get deployment pricing-sync -n "'"$QUESTION_ID"'" -o jsonpath="{.status.conditions[?(@.type==\"Progressing\")].reason}" 2>/dev/null)"
    [ "$status" = "True" ] && [ "$reason" = "NewReplicaSetAvailable" ]
  '

print_score
