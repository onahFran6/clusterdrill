#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q105-45-configmap-subpath-no-live-update${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "ConfigMap 'app-version' key version.txt = v2.0.0" \
  [ "$(kubectl get configmap app-version -n "$QUESTION_ID" -o jsonpath='{.data.version\.txt}' 2>/dev/null)" = "v2.0.0" ]

check_criterion "Pod 'version-display' is Running AND its mounted file actually shows v2.0.0 (proves the pod was recreated, not just the ConfigMap edited)" \
  bash -c '
    phase="$(kubectl get pod version-display -n "'"$QUESTION_ID"'" -o jsonpath="{.status.phase}" 2>/dev/null)"
    [ "$phase" = "Running" ] || exit 1
    content="$(kubectl exec -n "'"$QUESTION_ID"'" version-display -- cat /usr/share/nginx/html/version.txt 2>/dev/null)"
    [ "$content" = "v2.0.0" ]
  '

print_score
