#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q105-09-configmap-volume-subpath${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Pod 'landing-page' mounts a volume backed by ConfigMap site-config" \
  bash -c "kubectl get pod landing-page -n '$QUESTION_ID' -o json 2>/dev/null | grep -q '\"site-config\"'"

check_criterion "That mount uses subPath index.html" \
  [ "$(kget pod landing-page '{.spec.containers[0].volumeMounts[0].subPath}' -n "$QUESTION_ID")" = "index.html" ]

check_criterion "That mount targets /usr/share/nginx/html/index.html" \
  [ "$(kget pod landing-page '{.spec.containers[0].volumeMounts[0].mountPath}' -n "$QUESTION_ID")" = "/usr/share/nginx/html/index.html" ]

check_criterion "index.html content comes from the ConfigMap" \
  bash -c "kubectl exec -n '$QUESTION_ID' landing-page -- cat /usr/share/nginx/html/index.html 2>/dev/null | grep -q 'q105-09 landing page'"

check_criterion "index.html from the ConfigMap coexists with existing-notice.txt (subPath, not a directory mount)" \
  bash -c "kubectl exec -n '$QUESTION_ID' landing-page -- sh -c 'grep -q \"q105-09 landing page\" /usr/share/nginx/html/index.html && grep -q already-here /usr/share/nginx/html/existing-notice.txt'"

print_score
