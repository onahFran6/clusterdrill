#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q103-34-pod-terminationgraceperiod-window${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

pod_running() {
  kubectl wait --for=condition=Ready pod/slow-shutdown -n "$QUESTION_ID" --timeout=60s >/dev/null 2>&1
}

check_criterion "Pod 'slow-shutdown' exists in $QUESTION_ID" \
  resource_exists pod slow-shutdown -n "$QUESTION_ID"

check_criterion "Pod 'slow-shutdown' uses image busybox:1.36 and command 'sleep 3600'" \
  bash -c '
    img="$(kubectl get pod slow-shutdown -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.containers[0].image}" 2>/dev/null)"
    [ "$img" = "busybox:1.36" ] || exit 1
    cmd="$(kubectl get pod slow-shutdown -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.containers[0].command}" 2>/dev/null)"
    [ "$cmd" = "[\"sleep\",\"3600\"]" ]
  '

check_criterion "Pod 'slow-shutdown' has terminationGracePeriodSeconds set to 90" \
  [ "$(kget pod slow-shutdown '{.spec.terminationGracePeriodSeconds}' -n "$QUESTION_ID")" = "90" ]

check_criterion "Pod 'slow-shutdown' is Running and Ready" \
  pod_running

print_score
