#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q103-06-job-active-deadline-seconds${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

job_failed_with_deadline_exceeded() {
  kubectl wait --for=condition=Failed job/long-runner -n "$QUESTION_ID" --timeout=60s >/dev/null 2>&1 || return 1
  [ "$(kget job long-runner '{.status.conditions[?(@.type=="Failed")].reason}' -n "$QUESTION_ID")" = "DeadlineExceeded" ]
}

check_criterion "Job 'long-runner' exists in $QUESTION_ID" \
  resource_exists job long-runner -n "$QUESTION_ID"

check_criterion "Job 'long-runner' uses image busybox:1.36" \
  [ "$(kget job long-runner '{.spec.template.spec.containers[0].image}' -n "$QUESTION_ID")" = "busybox:1.36" ]

check_criterion "Job 'long-runner' activeDeadlineSeconds is set to 5" \
  [ "$(kget job long-runner '{.spec.activeDeadlineSeconds}' -n "$QUESTION_ID")" = "5" ]

check_criterion "Job 'long-runner' fails with reason DeadlineExceeded" \
  job_failed_with_deadline_exceeded

print_score
