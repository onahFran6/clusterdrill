#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q110-50-helm-values-schema-json-fix${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

STATUS_JSON="$(helm status demo -n "$QUESTION_ID" -o json 2>/dev/null)"
IS_DEPLOYED="no"
echo "$STATUS_JSON" | grep -q '"status":"deployed"' && IS_DEPLOYED="yes"
check_criterion "Release 'demo' is deployed" \
  [ "$IS_DEPLOYED" = "yes" ]

check_criterion "Deployment 'demo-worker-pool' has spec.replicas=5" \
  [ "$(kget deployment demo-worker-pool '{.spec.replicas}' -n "$QUESTION_ID")" = "5" ]

check_criterion "Deployment 'demo-worker-pool' has 5 available replicas" \
  [ "$(kget deployment demo-worker-pool '{.status.availableReplicas}' -n "$QUESTION_ID")" = "5" ]

print_score
