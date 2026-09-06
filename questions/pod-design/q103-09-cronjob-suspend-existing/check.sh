#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q103-09-cronjob-suspend-existing${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "CronJob 'metrics-rollup' is suspended" \
  [ "$(kget cronjob metrics-rollup '{.spec.suspend}' -n "$QUESTION_ID")" = "true" ]

print_score
