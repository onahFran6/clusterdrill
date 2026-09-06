#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q101-48-fix-job-activedeadlineseconds-premature-failure${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

job_completed_with_raised_deadline() {
  local i deadline succeeded image command_0 command_1 command_2
  for ((i = 0; i < 30; i++)); do
    deadline="$(kubectl get job batch-migrate -n "$QUESTION_ID" -o jsonpath='{.spec.activeDeadlineSeconds}' 2>/dev/null)"
    succeeded="$(kubectl get job batch-migrate -n "$QUESTION_ID" -o jsonpath='{.status.succeeded}' 2>/dev/null)"
    image="$(kubectl get job batch-migrate -n "$QUESTION_ID" -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null)"
    command_0="$(kubectl get job batch-migrate -n "$QUESTION_ID" -o jsonpath='{.spec.template.spec.containers[0].command[0]}' 2>/dev/null)"
    command_1="$(kubectl get job batch-migrate -n "$QUESTION_ID" -o jsonpath='{.spec.template.spec.containers[0].command[1]}' 2>/dev/null)"
    command_2="$(kubectl get job batch-migrate -n "$QUESTION_ID" -o jsonpath='{.spec.template.spec.containers[0].command[2]}' 2>/dev/null)"
    if [[ "$deadline" =~ ^[0-9]+$ ]] \
      && [ "$deadline" -ge 30 ] \
      && [ "$succeeded" = "1" ] \
      && [ "$image" = "busybox:1.36" ] \
      && [ "$command_0" = "sh" ] \
      && [ "$command_1" = "-c" ] \
      && [ "$command_2" = "sleep 20 && echo migrated" ]; then
      return 0
    fi
    sleep 2
  done
  return 1
}
check_criterion "Job 'batch-migrate' keeps its image/command, raises activeDeadlineSeconds to >=30, and completes successfully" \
  job_completed_with_raised_deadline

print_score
