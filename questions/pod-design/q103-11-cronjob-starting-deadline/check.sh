#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q103-11-cronjob-starting-deadline${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "CronJob 'stale-poll' startingDeadlineSeconds is 30" \
  [ "$(kget cronjob stale-poll '{.spec.startingDeadlineSeconds}' -n "$QUESTION_ID")" = "30" ]

print_score
