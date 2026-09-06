#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q101-47-fix-cronjob-concurrency-policy-pileup${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "CronJob 'log-compactor' has spec.concurrencyPolicy=Forbid" \
  bash -c "[ \"\$(kubectl get cronjob log-compactor -n '$QUESTION_ID' -o jsonpath='{.spec.concurrencyPolicy}' 2>/dev/null)\" = 'Forbid' ]"

check_criterion "CronJob 'log-compactor' schedule is unchanged at '* * * * *' and not suspended, with concurrencyPolicy fixed" \
  bash -c "
    [ \"\$(kubectl get cronjob log-compactor -n '$QUESTION_ID' -o jsonpath='{.spec.schedule}' 2>/dev/null)\" = '* * * * *' ] &&
    [ \"\$(kubectl get cronjob log-compactor -n '$QUESTION_ID' -o jsonpath='{.spec.suspend}' 2>/dev/null)\" != 'true' ] &&
    [ \"\$(kubectl get cronjob log-compactor -n '$QUESTION_ID' -o jsonpath='{.spec.concurrencyPolicy}' 2>/dev/null)\" = 'Forbid' ]
  "

print_score
