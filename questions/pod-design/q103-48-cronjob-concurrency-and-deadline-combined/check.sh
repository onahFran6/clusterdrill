#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q103-48-cronjob-concurrency-and-deadline-combined${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "CronJob 'ledger-close' concurrencyPolicy is Forbid" \
  [ "$(kget cronjob ledger-close '{.spec.concurrencyPolicy}' -n "$QUESTION_ID")" = "Forbid" ]

check_criterion "CronJob 'ledger-close' startingDeadlineSeconds is 20" \
  [ "$(kget cronjob ledger-close '{.spec.startingDeadlineSeconds}' -n "$QUESTION_ID")" = "20" ]

check_criterion "CronJob 'ledger-close' jobTemplate backoffLimit is 2" \
  [ "$(kget cronjob ledger-close '{.spec.jobTemplate.spec.backoffLimit}' -n "$QUESTION_ID")" = "2" ]

print_score
