#!/usr/bin/env bash
# No "set -e" - a failed criterion is a normal result, not a script error.
set -uo pipefail

QUESTION_ID="q104-50-deployment-missing-serviceaccount-blocks-rollout${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Deployment 'payments-worker' serviceAccountName is payments-runner and both replicas ready/updated" \
  bash -c '
    sa="$(kubectl get deployment payments-worker -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.serviceAccountName}" 2>/dev/null)"
    [ "$sa" = "payments-runner" ] || exit 1
    ready="$(kubectl get deployment payments-worker -n "'"$QUESTION_ID"'" -o jsonpath="{.status.readyReplicas}" 2>/dev/null)"
    updated="$(kubectl get deployment payments-worker -n "'"$QUESTION_ID"'" -o jsonpath="{.status.updatedReplicas}" 2>/dev/null)"
    [ "$ready" = "2" ] && [ "$updated" = "2" ]
  '

check_criterion "Deployment 'payments-worker' Progressing condition is True, reason NewReplicaSetAvailable" \
  bash -c '
    status="$(kubectl get deployment payments-worker -n "'"$QUESTION_ID"'" -o jsonpath="{.status.conditions[?(@.type==\"Progressing\")].status}" 2>/dev/null)"
    reason="$(kubectl get deployment payments-worker -n "'"$QUESTION_ID"'" -o jsonpath="{.status.conditions[?(@.type==\"Progressing\")].reason}" 2>/dev/null)"
    [ "$status" = "True" ] && [ "$reason" = "NewReplicaSetAvailable" ]
  '

print_score
