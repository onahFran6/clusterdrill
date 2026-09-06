#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q110-44-helm-required-function-value${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

STATUS_JSON="$(helm status demo -n "$QUESTION_ID" -o json 2>/dev/null)"
IS_DEPLOYED="no"
echo "$STATUS_JSON" | grep -q '"status":"deployed"' && IS_DEPLOYED="yes"
check_criterion "Release 'demo' is deployed" \
  [ "$IS_DEPLOYED" = "yes" ]

check_criterion "Secret 'demo-secret' apiKey is 'sk-live-92f3'" \
  bash -c "[ \"\$(kubectl get secret demo-secret -n '$QUESTION_ID' -o jsonpath='{.data.apiKey}' | base64 -d)\" = 'sk-live-92f3' ]"

print_score
