#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q103-05-job-work-queue-parallelism${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

completions_unset() {
  resource_exists job queue-workers -n "$QUESTION_ID" || return 1
  local completions
  completions="$(kget job queue-workers '{.spec.completions}' -n "$QUESTION_ID")"
  [ -z "$completions" ]
}

job_reaches_complete() {
  kubectl wait --for=condition=Complete job/queue-workers -n "$QUESTION_ID" --timeout=180s >/dev/null 2>&1
}

check_criterion "Job 'queue-workers' exists in $QUESTION_ID" \
  resource_exists job queue-workers -n "$QUESTION_ID"

check_criterion "Job 'queue-workers' uses image busybox:1.36" \
  [ "$(kget job queue-workers '{.spec.template.spec.containers[0].image}' -n "$QUESTION_ID")" = "busybox:1.36" ]

check_criterion "Job 'queue-workers' leaves completions unset (work-queue pattern)" \
  completions_unset

check_criterion "Job 'queue-workers' runs 4 pods in parallel" \
  [ "$(kget job queue-workers '{.spec.parallelism}' -n "$QUESTION_ID")" = "4" ]

check_criterion "Job 'queue-workers' reaches Complete" \
  job_reaches_complete

print_score
