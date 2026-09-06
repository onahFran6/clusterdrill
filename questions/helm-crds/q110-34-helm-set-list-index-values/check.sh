#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q110-34-helm-set-list-index-values${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "ConfigMap 'demo-router' exists in $QUESTION_ID" \
  resource_exists configmap demo-router -n "$QUESTION_ID"

check_criterion "ConfigMap hosts is 'api.example.com,admin.example.com' (list overridden via --set index syntax, in order)" \
  [ "$(kget configmap demo-router '{.data.hosts}' -n "$QUESTION_ID")" = "api.example.com,admin.example.com" ]

STATUS_JSON="$(helm status demo -n "$QUESTION_ID" -o json 2>/dev/null)"
IS_DEPLOYED="no"
echo "$STATUS_JSON" | grep -q '"status":"deployed"' && IS_DEPLOYED="yes"
check_criterion "Release 'demo' is deployed" \
  [ "$IS_DEPLOYED" = "yes" ]

print_score
