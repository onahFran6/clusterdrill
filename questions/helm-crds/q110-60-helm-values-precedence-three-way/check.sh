#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q110-60-helm-values-precedence-three-way${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

STATUS_JSON="$(helm status threeway -n "$QUESTION_ID" -o json 2>/dev/null)"
IS_DEPLOYED="no"
echo "$STATUS_JSON" | grep -q '"status":"deployed"' && IS_DEPLOYED="yes"
check_criterion "Release 'threeway' is deployed" \
  [ "$IS_DEPLOYED" = "yes" ]

check_criterion "Deployment 'threeway-threeway' has 5 replicas (--set beat both the chart default and -f)" \
  [ "$(kget deployment threeway-threeway '{.spec.replicas}' -n "$QUESTION_ID")" = "5" ]

check_criterion "ConfigMap 'threeway-threeway-extra' data.featureFlag is the literal string \"true\" (--set-string beat --set)" \
  [ "$(kget configmap threeway-threeway-extra '{.data.featureFlag}' -n "$QUESTION_ID")" = "true" ]

print_score
