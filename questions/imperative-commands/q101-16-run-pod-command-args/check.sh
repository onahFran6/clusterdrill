#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q101-16-run-pod-command-args${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Pod 'custom-cmd' exists in $QUESTION_ID" \
  resource_exists pod custom-cmd -n "$QUESTION_ID"

check_criterion "Pod 'custom-cmd' runs image 'busybox:1.36'" \
  [ "$(kget pod custom-cmd '{.spec.containers[0].image}' -n "$QUESTION_ID")" = "busybox:1.36" ]

command_includes_echo_hello() {
  kubectl get pod custom-cmd -n "$QUESTION_ID" \
    -o jsonpath='{.spec.containers[0].command[*]}{" "}{.spec.containers[0].args[*]}' 2>/dev/null \
    | grep -q 'hello-ckad'
}
check_criterion "Pod 'custom-cmd' container command/args include 'hello-ckad'" \
  command_includes_echo_hello

check_criterion "Pod 'custom-cmd' is Running" \
  [ "$(kget pod custom-cmd '{.status.phase}' -n "$QUESTION_ID")" = "Running" ]

print_score
