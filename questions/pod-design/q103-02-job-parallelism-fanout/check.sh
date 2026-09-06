#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q103-02-job-parallelism-fanout${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

job_completed_nine_times() {
  kubectl wait --for=condition=Complete job/render-fanout -n "$QUESTION_ID" --timeout=180s >/dev/null 2>&1 || return 1
  [ "$(kget job render-fanout '{.status.succeeded}' -n "$QUESTION_ID")" = "9" ]
}

check_criterion "Job 'render-fanout' exists in $QUESTION_ID" \
  resource_exists job render-fanout -n "$QUESTION_ID"

check_criterion "Job 'render-fanout' uses image busybox:1.36" \
  [ "$(kget job render-fanout '{.spec.template.spec.containers[0].image}' -n "$QUESTION_ID")" = "busybox:1.36" ]

check_criterion "Job 'render-fanout' requires 9 completions" \
  [ "$(kget job render-fanout '{.spec.completions}' -n "$QUESTION_ID")" = "9" ]

check_criterion "Job 'render-fanout' runs 3 pods in parallel" \
  [ "$(kget job render-fanout '{.spec.parallelism}' -n "$QUESTION_ID")" = "3" ]

check_criterion "Job 'render-fanout' has succeeded 9 times" \
  job_completed_nine_times

print_score
