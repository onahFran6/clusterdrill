#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q110-41-helm-notes-txt-value-substitution${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

STATUS_JSON="$(helm status demo -n "$QUESTION_ID" -o json 2>/dev/null)"
IS_DEPLOYED="no"
echo "$STATUS_JSON" | grep -q '"status":"deployed"' && IS_DEPLOYED="yes"
check_criterion "Release 'demo' is deployed" \
  [ "$IS_DEPLOYED" = "yes" ]

NOTES="$(helm get notes demo -n "$QUESTION_ID" 2>/dev/null)"
check_criterion "'helm get notes demo' shows 'Deployed payments-api version 1.0'" \
  bash -c "echo \"\$1\" | grep -qF 'Deployed payments-api version 1.0'" _ "$NOTES"

check_criterion "ConfigMap 'demo-onboarder' appName is 'payments-api'" \
  [ "$(kget configmap demo-onboarder '{.data.appName}' -n "$QUESTION_ID")" = "payments-api" ]

print_score
