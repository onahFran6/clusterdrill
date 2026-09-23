#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q110-52-helm-install-pinned-version-new-namespace${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

STATUS_JSON="$(helm status cache01 -n "$QUESTION_ID" -o json 2>/dev/null)"
IS_DEPLOYED="no"
echo "$STATUS_JSON" | grep -q '"status":"deployed"' && IS_DEPLOYED="yes"
check_criterion "Release 'cache01' is deployed" \
  [ "$IS_DEPLOYED" = "yes" ]

LIST_JSON="$(helm list -n "$QUESTION_ID" -o json 2>/dev/null)"
IS_V1="no"
echo "$LIST_JSON" | grep -q '"chart":"cache-1.0.0"' && IS_V1="yes"
check_criterion "Release 'cache01' was installed from chart version 1.0.0, not 2.0.0" \
  [ "$IS_V1" = "yes" ]

check_criterion "Deployment 'cache01-cache' runs redis:7.2-alpine (the 1.0.0 package's image)" \
  [ "$(kget deployment cache01-cache '{.spec.template.spec.containers[0].image}' -n "$QUESTION_ID")" = "redis:7.2-alpine" ]

print_score
