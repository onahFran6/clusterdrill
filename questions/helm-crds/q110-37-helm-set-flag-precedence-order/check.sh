#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q110-37-helm-set-flag-precedence-order${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "ConfigMap 'demo-tuner' exists in $QUESTION_ID" \
  resource_exists configmap demo-tuner -n "$QUESTION_ID"

check_criterion "ConfigMap logLevel is 'warn' (the later --set flag won)" \
  [ "$(kget configmap demo-tuner '{.data.logLevel}' -n "$QUESTION_ID")" = "warn" ]

STATUS_JSON="$(helm status demo -n "$QUESTION_ID" -o json 2>/dev/null)"
IS_DEPLOYED="no"
echo "$STATUS_JSON" | grep -q '"status":"deployed"' && IS_DEPLOYED="yes"
check_criterion "Release 'demo' is deployed" \
  [ "$IS_DEPLOYED" = "yes" ]

print_score
