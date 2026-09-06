#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q101-41-create-job-from-cronjob${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Job 'manual-report-run' exists in $QUESTION_ID" \
  resource_exists job manual-report-run -n "$QUESTION_ID"

check_criterion "Job 'manual-report-run' was created from CronJob 'nightly-report'" \
  bash -c "kubectl get job manual-report-run -n '$QUESTION_ID' -o jsonpath='{.metadata.annotations.cronjob\.kubernetes\.io/instantiate}' 2>/dev/null | grep -qx 'manual'"

job_completed() {
  local i
  for ((i = 0; i < 20; i++)); do
    if [ "$(kget job manual-report-run '{.status.succeeded}' -n "$QUESTION_ID")" = "1" ]; then
      return 0
    fi
    sleep 2
  done
  return 1
}
check_criterion "Job 'manual-report-run' completed successfully (status.succeeded=1)" \
  job_completed

print_score
