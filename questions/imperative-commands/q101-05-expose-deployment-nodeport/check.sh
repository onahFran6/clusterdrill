#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q101-05-expose-deployment-nodeport${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Service 'frontend-np' exists in $QUESTION_ID" \
  resource_exists service frontend-np -n "$QUESTION_ID"

check_criterion "Service 'frontend-np' is type NodePort" \
  [ "$(kget service frontend-np '{.spec.type}' -n "$QUESTION_ID")" = "NodePort" ]

check_criterion "Service 'frontend-np' listens on port 8080" \
  [ "$(kget service frontend-np '{.spec.ports[0].port}' -n "$QUESTION_ID")" = "8080" ]

check_criterion "Service 'frontend-np' targets container port 80" \
  [ "$(kget service frontend-np '{.spec.ports[0].targetPort}' -n "$QUESTION_ID")" = "80" ]

check_criterion "Service 'frontend-np' selects app=frontend" \
  [ "$(kget service frontend-np '{.spec.selector.app}' -n "$QUESTION_ID")" = "frontend" ]

print_score
