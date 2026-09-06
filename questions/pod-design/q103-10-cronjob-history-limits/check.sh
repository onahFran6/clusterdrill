#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q103-10-cronjob-history-limits${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "CronJob 'audit-scan' successfulJobsHistoryLimit is 2" \
  [ "$(kget cronjob audit-scan '{.spec.successfulJobsHistoryLimit}' -n "$QUESTION_ID")" = "2" ]

check_criterion "CronJob 'audit-scan' failedJobsHistoryLimit is 0" \
  [ "$(kget cronjob audit-scan '{.spec.failedJobsHistoryLimit}' -n "$QUESTION_ID")" = "0" ]

print_score
