#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q103-21-job-suspend-unsuspend${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

# setup.sh already creates the Job (suspended), so a bare "Job exists" check
# would be trivially true before the candidate touches anything. Fold
# existence into the same criterion as the field that actually has to
# change - suspend starts true and only the candidate flips it to false.
job_is_unsuspended() {
  resource_exists job archive-purge -n "$QUESTION_ID" || return 1
  [ "$(kget job archive-purge '{.spec.suspend}' -n "$QUESTION_ID")" = "false" ]
}

# Only reachable once the Job is actually running - polls for a stable
# Complete condition rather than a single snapshot, since a just-unsuspended
# Job's pod takes a moment to schedule, run, and report status.
job_completed_once() {
  resource_exists job archive-purge -n "$QUESTION_ID" || return 1
  kubectl wait --for=condition=Complete job/archive-purge -n "$QUESTION_ID" --timeout=180s >/dev/null 2>&1 || return 1
  [ "$(kget job archive-purge '{.status.succeeded}' -n "$QUESTION_ID")" = "1" ]
}

check_criterion "Job 'archive-purge' is unsuspended (spec.suspend=false)" \
  job_is_unsuspended

check_criterion "Job 'archive-purge' has completed successfully (status.succeeded=1)" \
  job_completed_once

print_score
