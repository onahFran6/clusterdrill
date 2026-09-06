#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q103-35-job-default-single-completion-fix${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

# Everything bundled into ONE criterion on purpose. setup.sh already creates
# the Job with the right image/command (and a Job named onetime-cleanup
# already exists at all), so each of those facts alone would trivially pass
# before the candidate does anything. Gating everything - including plain
# existence - on the same criterion as the real fix (completions actually
# corrected) keeps the unsolved score genuinely 0/1.
job_fixed_and_ran_once() {
  resource_exists job onetime-cleanup -n "$QUESTION_ID" || return 1

  local c img cmd
  c="$(kubectl get job onetime-cleanup -n "$QUESTION_ID" -o jsonpath='{.spec.completions}' 2>/dev/null)"
  [ -z "$c" ] || [ "$c" = "1" ] || return 1

  img="$(kubectl get job onetime-cleanup -n "$QUESTION_ID" -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null)"
  [ "$img" = "busybox:1.36" ] || return 1
  cmd="$(kubectl get job onetime-cleanup -n "$QUESTION_ID" -o jsonpath='{.spec.template.spec.containers[0].command}' 2>/dev/null)"
  [ "$cmd" = '["echo","cleaning"]' ] || return 1

  kubectl wait --for=condition=Complete job/onetime-cleanup -n "$QUESTION_ID" --timeout=90s >/dev/null 2>&1 || return 1
  [ "$(kget job onetime-cleanup '{.status.succeeded}' -n "$QUESTION_ID")" = "1" ]
}

check_criterion "Job 'onetime-cleanup' was recreated with completions unset/1, keeps its image/command, and completed exactly once" \
  job_fixed_and_ran_once

print_score
