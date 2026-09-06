#!/usr/bin/env bash
# No "set -e" - a failed criterion is a normal result, not a script error.
set -uo pipefail

QUESTION_ID="q110-46-helm-hook-weight-ordering-two-hooks${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

STATUS_JSON="$(helm status demo -n "$QUESTION_ID" -o json 2>/dev/null)"
check_criterion "Release 'demo' exists in $QUESTION_ID" \
  [ -n "$STATUS_JSON" ]

IS_DEPLOYED="no"
echo "$STATUS_JSON" | grep -q '"status":"deployed"' && IS_DEPLOYED="yes"
check_criterion "Release 'demo' status is 'deployed'" \
  [ "$IS_DEPLOYED" = "yes" ]

check_criterion "Hook Job 'demo-seed-data' completed successfully" \
  [ "$(kget job demo-seed-data '{.status.succeeded}' -n "$QUESTION_ID")" = "1" ]

check_criterion "Hook Job 'demo-verify-data' completed successfully (proving seed-data ran first)" \
  [ "$(kget job demo-verify-data '{.status.succeeded}' -n "$QUESTION_ID")" = "1" ]

print_score
