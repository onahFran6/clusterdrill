#!/usr/bin/env bash
# No "set -e" - a failed criterion is a normal result, not a script error.
set -uo pipefail

QUESTION_ID="q110-25-helm-broken-hook-preinstall${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

RELEASE_STATUS="$(helm status gate -n "$QUESTION_ID" -o json 2>/dev/null)"

check_criterion "Release 'gate' exists in $QUESTION_ID" \
  [ -n "$RELEASE_STATUS" ]

RELEASE_STATE="$(echo "$RELEASE_STATUS" | grep -o '"status":"[^"]*"' | head -1)"
check_criterion "Release 'gate' status is 'deployed'" \
  [ "$RELEASE_STATE" = '"status":"deployed"' ]

check_criterion "Deployment 'gate-gatekeeper' exists in $QUESTION_ID" \
  resource_exists deployment gate-gatekeeper -n "$QUESTION_ID"

AVAILABLE_REPLICAS="$(kget deployment gate-gatekeeper '{.status.availableReplicas}' -n "$QUESTION_ID")"
check_criterion "Deployment 'gate-gatekeeper' has 1 available replica" \
  [ "$AVAILABLE_REPLICAS" = "1" ]

check_criterion "Pre-install hook Job 'gate-gatekeeper-pre-install' completed successfully (status.succeeded=1)" \
  [ "$(kget job gate-gatekeeper-pre-install '{.status.succeeded}' -n "$QUESTION_ID")" = "1" ]

print_score
