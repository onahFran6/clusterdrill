#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q101-35-create-configmap-from-file${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "ConfigMap 'app-props' exists in $QUESTION_ID" \
  resource_exists configmap app-props -n "$QUESTION_ID"

check_criterion "ConfigMap 'app-props' has key 'app.properties'" \
  bash -c "kubectl get configmap app-props -n '$QUESTION_ID' -o jsonpath='{.data.app\.properties}' 2>/dev/null | grep -q ."

check_criterion "ConfigMap 'app-props' key 'app.properties' has the exact seeded content" \
  bash -c "
    VAL=\$(kubectl get configmap app-props -n '$QUESTION_ID' -o jsonpath='{.data.app\.properties}' 2>/dev/null)
    EXPECTED=\$(printf 'log.level=warn\ncache.enabled=true\n')
    [ \"\$VAL\" = \"\$EXPECTED\" ]
  "

print_score
