#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q103-07-cronjob-fix-schedule${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "CronJob 'nightly-report' schedule is '0 2 * * *'" \
  [ "$(kget cronjob nightly-report '{.spec.schedule}' -n "$QUESTION_ID")" = "0 2 * * *" ]

print_score
