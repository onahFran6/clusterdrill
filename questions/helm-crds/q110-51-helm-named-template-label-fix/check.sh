#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q110-51-helm-named-template-label-fix${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

STATUS_JSON="$(helm status demo -n "$QUESTION_ID" -o json 2>/dev/null)"
IS_DEPLOYED="no"
echo "$STATUS_JSON" | grep -q '"status":"deployed"' && IS_DEPLOYED="yes"
check_criterion "Release 'demo' is deployed" \
  [ "$IS_DEPLOYED" = "yes" ]

check_criterion "Deployment 'demo-webapp' has 1 available replica" \
  [ "$(kget deployment demo-webapp '{.status.availableReplicas}' -n "$QUESTION_ID")" = "1" ]

check_criterion "Deployment 'demo-webapp' carries label app.kubernetes.io/version=2.3.1 from the shared named template" \
  [ "$(kget deployment demo-webapp '{.metadata.labels.app\.kubernetes\.io/version}' -n "$QUESTION_ID")" = "2.3.1" ]

check_criterion "ConfigMap 'demo-config' carries label app.kubernetes.io/version=2.3.1 from the same shared named template" \
  [ "$(kget configmap demo-config '{.metadata.labels.app\.kubernetes\.io/version}' -n "$QUESTION_ID")" = "2.3.1" ]

print_score
