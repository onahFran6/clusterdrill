#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q101-40-create-configmap-from-env-file${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "ConfigMap 'service-env' exists in $QUESTION_ID" \
  resource_exists configmap service-env -n "$QUESTION_ID"

check_criterion "ConfigMap 'service-env' has key RETRY_COUNT=3" \
  [ "$(kget configmap service-env '{.data.RETRY_COUNT}' -n "$QUESTION_ID")" = "3" ]

check_criterion "ConfigMap 'service-env' has key TIMEOUT_SECONDS=30" \
  [ "$(kget configmap service-env '{.data.TIMEOUT_SECONDS}' -n "$QUESTION_ID")" = "30" ]

check_criterion "ConfigMap 'service-env' has exactly the two expected keys (not one whole-file key)" \
  bash -c "
    COUNT=\$(kubectl get configmap service-env -n '$QUESTION_ID' -o jsonpath='{.data}' 2>/dev/null | grep -o '\"[A-Za-z_]*\":' | wc -l | tr -d ' ')
    [ \"\$COUNT\" = '2' ]
  "

print_score
