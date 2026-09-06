#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q101-09-create-configmap-literal${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "ConfigMap 'app-config' exists in $QUESTION_ID" \
  resource_exists configmap app-config -n "$QUESTION_ID"

check_criterion "ConfigMap 'app-config' has LOG_LEVEL=info" \
  [ "$(kget configmap app-config '{.data.LOG_LEVEL}' -n "$QUESTION_ID")" = "info" ]

check_criterion "ConfigMap 'app-config' has MAX_CONNECTIONS=100" \
  [ "$(kget configmap app-config '{.data.MAX_CONNECTIONS}' -n "$QUESTION_ID")" = "100" ]

print_score
