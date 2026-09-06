#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q106-25-configmap-immutable-flag${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

# "ConfigMap exists" is trivially true right after setup.sh, so it is
# bundled into the same criterion as the actual fix (immutable=true) rather
# than checked standalone - otherwise the unsolved state would already score
# 1/2. The unchanged-data checks are folded in too, so a candidate can't
# score by deleting and recreating app-config with the flag set but garbled
# data.
check_criterion "app-config exists, is marked immutable=true, and both original keys/values are unchanged" \
  bash -c "
    kubectl get configmap app-config -n '$QUESTION_ID' >/dev/null 2>&1 && \
    [ \"\$(kubectl get configmap app-config -n '$QUESTION_ID' -o jsonpath='{.immutable}' 2>/dev/null)\" = 'true' ] && \
    [ \"\$(kubectl get configmap app-config -n '$QUESTION_ID' -o jsonpath='{.data.LOG_LEVEL}' 2>/dev/null)\" = 'info' ] && \
    [ \"\$(kubectl get configmap app-config -n '$QUESTION_ID' -o jsonpath='{.data.FEATURE_FLAG}' 2>/dev/null)\" = 'enabled' ]
  "

print_score
