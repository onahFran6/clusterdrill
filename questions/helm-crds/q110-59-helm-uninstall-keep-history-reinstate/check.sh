#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q110-59-helm-uninstall-keep-history-reinstate${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

# setup.sh already leaves 'app' deployed at revision 1, so "deployed" alone
# is trivially true before the candidate does anything. Gate everything on
# real evidence of an uninstall-then-rollback cycle: an "uninstalled"
# revision actually present in history (only --keep-history leaves this
# behind) plus more than one revision overall (proves the reinstate step
# advanced history rather than the candidate doing nothing).
HISTORY_JSON="$(helm history app -n "$QUESTION_ID" -o json 2>/dev/null)"
WAS_UNINSTALLED="no"
echo "$HISTORY_JSON" | grep -q '"status":"uninstalled"' && WAS_UNINSTALLED="yes"

REVISION_COUNT="$(echo "$HISTORY_JSON" | grep -o '"revision":[0-9]*' | wc -l | tr -d ' ')"
ADVANCED="no"
[ "$WAS_UNINSTALLED" = "yes" ] && [ "${REVISION_COUNT:-0}" -ge 2 ] && ADVANCED="yes"

check_criterion "History shows a real uninstall-with-keep-history-then-reinstate cycle (an 'uninstalled' revision plus a later one)" \
  [ "$ADVANCED" = "yes" ]

STATUS_JSON="$(helm status app -n "$QUESTION_ID" -o json 2>/dev/null)"
IS_DEPLOYED="no"
[ "$ADVANCED" = "yes" ] && echo "$STATUS_JSON" | grep -q '"status":"deployed"' && IS_DEPLOYED="yes"
check_criterion "Release 'app' is 'deployed' again after being brought back" \
  [ "$IS_DEPLOYED" = "yes" ]

AVAILABLE="no"
[ "$IS_DEPLOYED" = "yes" ] && [ "$(kget deployment app-archiveapp '{.status.availableReplicas}' -n "$QUESTION_ID")" = "1" ] && AVAILABLE="yes"
check_criterion "Deployment 'app-archiveapp' is available again" \
  [ "$AVAILABLE" = "yes" ]

print_score
