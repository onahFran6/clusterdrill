#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q107-07-diagnose-crashloop-badcommand${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Pod 'batch-worker' phase is Running" \
  [ "$(kget pod batch-worker '{.status.phase}' -n "$QUESTION_ID")" = "Running" ]

check_criterion "Pod 'batch-worker' container is Ready" \
  [ "$(kget pod batch-worker '{.status.containerStatuses[0].ready}' -n "$QUESTION_ID")" = "true" ]

check_criterion "Pod 'batch-worker' has not restarted in the last check (no active crash loop)" \
  [ "$(kget pod batch-worker '{.status.containerStatuses[0].state.running}' -n "$QUESTION_ID")" != "" ]

print_score
