#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q110-33-helm-set-string-flag${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "ConfigMap 'demo-flagger' exists in $QUESTION_ID" \
  resource_exists configmap demo-flagger -n "$QUESTION_ID"

check_criterion "ConfigMap status is 'enabled' (legacyMode string \"false\" is truthy in the template)" \
  [ "$(kget configmap demo-flagger '{.data.status}' -n "$QUESTION_ID")" = "enabled" ]

STATUS_JSON="$(helm status demo -n "$QUESTION_ID" -o json 2>/dev/null)"
IS_DEPLOYED="no"
echo "$STATUS_JSON" | grep -q '"status":"deployed"' && IS_DEPLOYED="yes"
check_criterion "Release 'demo' is deployed" \
  [ "$IS_DEPLOYED" = "yes" ]

print_score
