#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q110-40-helm-chart-local-subchart-dependency${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

STATUS_JSON="$(helm status demo -n "$QUESTION_ID" -o json 2>/dev/null)"
IS_DEPLOYED="no"
echo "$STATUS_JSON" | grep -q '"status":"deployed"' && IS_DEPLOYED="yes"
check_criterion "Release 'demo' is deployed" \
  [ "$IS_DEPLOYED" = "yes" ]

check_criterion "Deployment 'demo-webapp' (parent chart) has 1 available replica" \
  [ "$(kget deployment demo-webapp '{.status.availableReplicas}' -n "$QUESTION_ID")" = "1" ]

check_criterion "ConfigMap 'demo-cache' (subchart) exists with ttlSeconds=300" \
  [ "$(kget configmap demo-cache '{.data.ttlSeconds}' -n "$QUESTION_ID")" = "300" ]

print_score
