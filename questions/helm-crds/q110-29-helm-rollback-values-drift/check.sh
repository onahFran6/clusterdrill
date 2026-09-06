#!/usr/bin/env bash
# No "set -e" - a failed criterion is a normal result, not a script error.
set -uo pipefail

QUESTION_ID="q110-29-helm-rollback-values-drift${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

DEPLOY_MODE="$(kget deployment app-configurable '{.spec.template.spec.containers[0].env[?(@.name=="APP_MODE")].value}' -n "$QUESTION_ID")"
check_criterion "Deployment 'app-configurable' container env APP_MODE=stable" \
  [ "$DEPLOY_MODE" = "stable" ]

CM_MODE="$(kget configmap app-configurable-cfg '{.data.mode}' -n "$QUESTION_ID")"
check_criterion "ConfigMap 'app-configurable-cfg' data.mode=stable" \
  [ "$CM_MODE" = "stable" ]

HISTORY_JSON="$(helm history app -n "$QUESTION_ID" -o json 2>/dev/null)"
LATEST_ENTRY="$(echo "$HISTORY_JSON" | grep -o '{[^}]*}' | tail -1)"

LATEST_REV="$(echo "$LATEST_ENTRY" | grep -o '"revision":[0-9]*' | cut -d: -f2)"
LATEST_REV="${LATEST_REV:-0}"
check_criterion "Release 'app' advanced to revision 4 (a rollback, not a manual edit)" \
  [ "$LATEST_REV" -eq 4 ]

LATEST_STATUS="$(echo "$LATEST_ENTRY" | grep -o '"status":"[^"]*"' | cut -d'"' -f4)"
STATUS_OK="no"
[ "$LATEST_REV" -eq 4 ] && [ "$LATEST_STATUS" = "deployed" ] && STATUS_OK="yes"
check_criterion "Revision 4 of release 'app' has status deployed" \
  [ "$STATUS_OK" = "yes" ]

LATEST_DESC="$(echo "$LATEST_ENTRY" | grep -o '"description":"[^"]*"' | cut -d'"' -f4)"
DESC_OK="no"
[ "$LATEST_REV" -eq 4 ] && [ "$LATEST_DESC" = "Rollback to 1" ] && DESC_OK="yes"
check_criterion "Revision 4 description contains 'Rollback to 1'" \
  [ "$DESC_OK" = "yes" ]

print_score
