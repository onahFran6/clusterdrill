#!/usr/bin/env bash
# No `set -e` - a failed criterion is a normal result, not a script error.
set -uo pipefail

QUESTION_ID="q103-32-cronjob-concurrencypolicy-replace-slow-run${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

# Bundled into one criterion (not "schedule unchanged" as a separate check) -
# schedule "* * * * *" is already true immediately after setup.sh, before the
# candidate does anything, so a separate criterion for it would score
# trivially PASS pre-solve. Gating everything on concurrencyPolicy actually
# being Replace keeps the unsolved score genuinely 0/1.
check_criterion "CronJob 'heavy-sync' concurrencyPolicy is Replace AND schedule is unchanged (every minute)" \
  bash -c '
    policy="$(kubectl get cronjob heavy-sync -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.concurrencyPolicy}" 2>/dev/null)"
    [ "$policy" = "Replace" ] || exit 1
    schedule="$(kubectl get cronjob heavy-sync -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.schedule}" 2>/dev/null)"
    [ "$schedule" = "* * * * *" ]
  '

print_score
