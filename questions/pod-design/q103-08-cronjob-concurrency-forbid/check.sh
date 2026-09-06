#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q103-08-cronjob-concurrency-forbid${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "CronJob 'slow-sync' concurrencyPolicy is Forbid" \
  [ "$(kget cronjob slow-sync '{.spec.concurrencyPolicy}' -n "$QUESTION_ID")" = "Forbid" ]

print_score
