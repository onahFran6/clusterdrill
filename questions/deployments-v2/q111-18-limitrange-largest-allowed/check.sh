#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q111-18-limitrange-largest-allowed${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "'oven' runs 3/3 pods at the largest memory the LimitRange allows (512Mi req+limit)" \
  bash -c '
    rmem="$(kubectl get deployment oven -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.containers[0].resources.requests.memory}" 2>/dev/null)"
    lmem="$(kubectl get deployment oven -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.containers[0].resources.limits.memory}" 2>/dev/null)"
    ready="$(kubectl get deployment oven -n "'"$QUESTION_ID"'" -o jsonpath="{.status.readyReplicas}" 2>/dev/null)"
    [ "$rmem" = "512Mi" ] && [ "$lmem" = "512Mi" ] && [ "$ready" = "3" ]
  '

# bread's own pod has never needed a fix - its values only prove the
# LimitRange's default/defaultRequest were applied at admission, so this
# is guarded on oven's own fix landing first, or it would trivially pass
# before the candidate does anything.
check_criterion "'bread's running pod picked up the LimitRange defaults (128Mi req, 256Mi limit)" \
  bash -c '
    oven_ready="$(kubectl get deployment oven -n "'"$QUESTION_ID"'" -o jsonpath="{.status.readyReplicas}" 2>/dev/null)"
    [ "$oven_ready" = "3" ] || exit 1
    pod="$(newest_pod_name "'"$QUESTION_ID"'" app=bread)"
    [ -n "$pod" ] || exit 1
    rmem="$(kubectl get pod "$pod" -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.containers[0].resources.requests.memory}" 2>/dev/null)"
    lmem="$(kubectl get pod "$pod" -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.containers[0].resources.limits.memory}" 2>/dev/null)"
    [ "$rmem" = "128Mi" ] && [ "$lmem" = "256Mi" ]
  '

print_score
