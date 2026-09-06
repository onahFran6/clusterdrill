#!/usr/bin/env bash
# No "set -e" - a failed criterion is a normal result, not a script error.
set -uo pipefail

QUESTION_ID="q107-32-readiness-successthreshold-recovery${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

# Bundled together - Ready=true is already true straight out of setup.sh
# regardless of successThreshold, so checking it alone would be vacuously
# true before the candidate does anything (false positive).
check_criterion "Pod 'flaky-backend' readinessProbe.successThreshold is 3, other probe fields unchanged, and the Pod is Ready" \
  bash -c '
    st="$(kubectl get pod flaky-backend -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.containers[0].readinessProbe.successThreshold}" 2>/dev/null)"
    [ "$st" = "3" ] || exit 1
    path="$(kubectl get pod flaky-backend -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.containers[0].readinessProbe.httpGet.path}" 2>/dev/null)"
    port="$(kubectl get pod flaky-backend -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.containers[0].readinessProbe.httpGet.port}" 2>/dev/null)"
    [ "$path" = "/" ] && [ "$port" = "80" ] || exit 1
    ready="$(kubectl get pod flaky-backend -n "'"$QUESTION_ID"'" -o jsonpath="{.status.conditions[?(@.type==\"Ready\")].status}" 2>/dev/null)"
    [ "$ready" = "True" ]
  '

print_score
