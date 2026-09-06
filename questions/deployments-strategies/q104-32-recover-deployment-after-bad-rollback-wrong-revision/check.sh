#!/usr/bin/env bash
# No "set -e" - a failed criterion is a normal result, not a script error.
set -uo pipefail

QUESTION_ID="q104-32-recover-deployment-after-bad-rollback-wrong-revision${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Deployment 'billing-sync' container image is busybox:1.35 and has 2 ready replicas" \
  bash -c '
    image="$(kubectl get deployment billing-sync -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.containers[0].image}" 2>/dev/null)"
    [ "$image" = "busybox:1.35" ] || exit 1
    kubectl rollout status deployment/billing-sync -n "'"$QUESTION_ID"'" --timeout=30s >/dev/null 2>&1 || exit 1
    ready="$(kubectl get deployment billing-sync -n "'"$QUESTION_ID"'" -o jsonpath="{.status.readyReplicas}" 2>/dev/null)"
    [ "$ready" = "2" ]
  '

print_score
