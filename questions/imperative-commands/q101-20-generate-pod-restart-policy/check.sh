#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q101-20-generate-pod-restart-policy${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Pod 'one-shot-task' exists in $QUESTION_ID" \
  resource_exists pod one-shot-task -n "$QUESTION_ID"

check_criterion "Pod 'one-shot-task' runs image 'busybox:1.36'" \
  [ "$(kget pod one-shot-task '{.spec.containers[0].image}' -n "$QUESTION_ID")" = "busybox:1.36" ]

check_criterion "Pod 'one-shot-task' has restartPolicy=Never" \
  [ "$(kget pod one-shot-task '{.spec.restartPolicy}' -n "$QUESTION_ID")" = "Never" ]

command_includes_echo_done() {
  kubectl get pod one-shot-task -n "$QUESTION_ID" \
    -o jsonpath='{.spec.containers[0].command[*]}{" "}{.spec.containers[0].args[*]}' 2>/dev/null \
    | grep -q 'echo done\|done'
}
check_criterion "Pod 'one-shot-task' command runs 'echo done'" \
  command_includes_echo_done

print_score
