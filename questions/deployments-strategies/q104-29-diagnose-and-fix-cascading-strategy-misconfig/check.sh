#!/usr/bin/env bash
# No "set -e" - a failed criterion is a normal result, not a script error.
set -uo pipefail

QUESTION_ID="q104-29-diagnose-and-fix-cascading-strategy-misconfig${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

# Bundled into one criterion - the probe path, strategy fields, and
# availableReplicas are all part of the same regression/fix, and none of
# them are true in the unsolved (outage) state, so bundling doesn't
# introduce a trivial-pass risk here (unlike splitting a pre-existing
# invariant out of a changed value).
check_criterion "readinessProbe path is / AND maxUnavailable=0 AND maxSurge=1 AND availableReplicas=2" \
  bash -c '
    path="$(kubectl get deployment payments-web -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.containers[0].readinessProbe.httpGet.path}" 2>/dev/null)"
    [ "$path" = "/" ] || exit 1
    max_unavail="$(kubectl get deployment payments-web -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.strategy.rollingUpdate.maxUnavailable}" 2>/dev/null)"
    [ "$max_unavail" = "0" ] || exit 1
    max_surge="$(kubectl get deployment payments-web -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.strategy.rollingUpdate.maxSurge}" 2>/dev/null)"
    [ "$max_surge" = "1" ] || exit 1
    kubectl rollout status deployment/payments-web -n "'"$QUESTION_ID"'" --timeout=30s >/dev/null 2>&1 || exit 1
    avail="$(kubectl get deployment payments-web -n "'"$QUESTION_ID"'" -o jsonpath="{.status.availableReplicas}" 2>/dev/null)"
    [ "$avail" = "2" ]
  '

print_score
