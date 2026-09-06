#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q110-01-helm-install-release${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

RELEASE_STATUS="$(helm status hello-app -n "$QUESTION_ID" -o json 2>/dev/null)"

check_criterion "Release 'hello-app' exists in $QUESTION_ID" \
  [ -n "$RELEASE_STATUS" ]

RELEASE_NAME_FIELD="$(echo "$RELEASE_STATUS" | grep -o '"name":"[^"]*"' | head -1)"
check_criterion "Release name is 'hello-app'" \
  [ "$RELEASE_NAME_FIELD" = '"name":"hello-app"' ]

RELEASE_STATE="$(echo "$RELEASE_STATUS" | grep -o '"status":"[^"]*"' | head -1)"
check_criterion "Release status is 'deployed'" \
  [ "$RELEASE_STATE" = '"status":"deployed"' ]

check_criterion "Deployment 'hello-app-greeter' exists in $QUESTION_ID" \
  resource_exists deployment hello-app-greeter -n "$QUESTION_ID"

check_criterion "Deployment 'hello-app-greeter' is available" \
  [ "$(kget deployment hello-app-greeter '{.status.availableReplicas}' -n "$QUESTION_ID")" = "1" ]

print_score
