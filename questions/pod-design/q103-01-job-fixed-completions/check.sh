#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q103-01-job-fixed-completions${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

# Job's parallelism defaults to 1 when the field is omitted entirely, so
# "one at a time" is satisfied by either an explicit 1 or an unset field -
# but only once the Job itself actually exists.
job_runs_sequentially() {
  resource_exists job digest-batch -n "$QUESTION_ID" || return 1
  local parallelism
  parallelism="$(kget job digest-batch '{.spec.parallelism}' -n "$QUESTION_ID")"
  [ -z "$parallelism" ] || [ "$parallelism" = "1" ]
}

job_completed_six_times() {
  kubectl wait --for=condition=Complete job/digest-batch -n "$QUESTION_ID" --timeout=180s >/dev/null 2>&1 || return 1
  [ "$(kget job digest-batch '{.status.succeeded}' -n "$QUESTION_ID")" = "6" ]
}

check_criterion "Job 'digest-batch' exists in $QUESTION_ID" \
  resource_exists job digest-batch -n "$QUESTION_ID"

check_criterion "Job 'digest-batch' uses image busybox:1.36" \
  [ "$(kget job digest-batch '{.spec.template.spec.containers[0].image}' -n "$QUESTION_ID")" = "busybox:1.36" ]

check_criterion "Job 'digest-batch' requires 6 completions" \
  [ "$(kget job digest-batch '{.spec.completions}' -n "$QUESTION_ID")" = "6" ]

check_criterion "Job 'digest-batch' runs pods one at a time (parallelism unset or 1)" \
  job_runs_sequentially

check_criterion "Job 'digest-batch' has succeeded 6 times" \
  job_completed_six_times

print_score
