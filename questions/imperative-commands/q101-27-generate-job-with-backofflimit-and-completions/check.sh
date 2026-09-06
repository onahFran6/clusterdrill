#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q101-27-generate-job-with-backofflimit-and-completions${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Job 'batch-verify' exists in $QUESTION_ID" \
  resource_exists job batch-verify -n "$QUESTION_ID"

check_criterion "Job 'batch-verify' uses image 'busybox:1.36'" \
  [ "$(kget job batch-verify '{.spec.template.spec.containers[0].image}' -n "$QUESTION_ID")" = "busybox:1.36" ]

command_includes_echo() {
  kubectl get job batch-verify -n "$QUESTION_ID" \
    -o jsonpath='{.spec.template.spec.containers[0].command[*]}{" "}{.spec.template.spec.containers[0].args[*]}' 2>/dev/null \
    | grep -q 'verifying'
}
check_criterion "Job 'batch-verify' command includes the verify script" \
  command_includes_echo

check_criterion "Job 'batch-verify' has spec.completions=4" \
  [ "$(kget job batch-verify '{.spec.completions}' -n "$QUESTION_ID")" = "4" ]

check_criterion "Job 'batch-verify' has spec.parallelism=2" \
  [ "$(kget job batch-verify '{.spec.parallelism}' -n "$QUESTION_ID")" = "2" ]

check_criterion "Job 'batch-verify' has spec.backoffLimit=1" \
  [ "$(kget job batch-verify '{.spec.backoffLimit}' -n "$QUESTION_ID")" = "1" ]

# Wait (bounded) for the Job to actually finish all 4 successful completions -
# this is the one criterion that proves the candidate didn't just set the
# fields without letting the Job run to completion.
job_reached_four_successes() {
  local i
  for ((i = 0; i < 30; i++)); do
    if [ "$(kget job batch-verify '{.status.succeeded}' -n "$QUESTION_ID")" = "4" ]; then
      return 0
    fi
    sleep 2
  done
  return 1
}
check_criterion "Job 'batch-verify' has status.succeeded=4" \
  job_reached_four_successes

print_score
