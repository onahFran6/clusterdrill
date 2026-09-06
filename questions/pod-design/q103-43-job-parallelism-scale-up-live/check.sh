#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q103-43-job-parallelism-scale-up-live${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

job_finished_at_parallelism_3() {
  [ "$(kget job speedy-batch '{.spec.parallelism}' -n "$QUESTION_ID")" = "3" ] || return 1
  kubectl wait --for=condition=Complete job/speedy-batch -n "$QUESTION_ID" --timeout=120s >/dev/null 2>&1 || return 1
  [ "$(kget job speedy-batch '{.status.succeeded}' -n "$QUESTION_ID")" = "6" ]
}

check_criterion "Job 'speedy-batch' has parallelism=3 and reports 6/6 successful completions" \
  job_finished_at_parallelism_3

print_score
