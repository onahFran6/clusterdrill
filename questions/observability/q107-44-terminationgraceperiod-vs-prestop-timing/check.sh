#!/usr/bin/env bash
# No "set -e" - a failed criterion is a normal result, not a script error.
set -uo pipefail

QUESTION_ID="q107-44-terminationgraceperiod-vs-prestop-timing${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Pod 'connection-drainer' terminationGracePeriodSeconds is at least 15 (enough for the 8s preStop to finish, plus margin), preStop command unchanged, and the Pod is Ready" \
  bash -c '
    tgps="$(kubectl get pod connection-drainer -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.terminationGracePeriodSeconds}" 2>/dev/null)"
    [ -n "$tgps" ] && [ "$tgps" -ge 15 ] 2>/dev/null || exit 1
    prestop="$(kubectl get pod connection-drainer -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.containers[0].lifecycle.preStop.exec.command[*]}" 2>/dev/null)"
    [ "$prestop" = "sh -c sleep 8" ] || exit 1
    ready="$(kubectl get pod connection-drainer -n "'"$QUESTION_ID"'" -o jsonpath="{.status.conditions[?(@.type==\"Ready\")].status}" 2>/dev/null)"
    [ "$ready" = "True" ]
  '

print_score
