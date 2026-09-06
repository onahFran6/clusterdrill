#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q101-45-fix-imagepullbackoff-wrong-tag${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Pod 'worker-app' image is corrected to nginx:1.25-alpine" \
  bash -c "[ \"\$(kubectl get pod worker-app -n '$QUESTION_ID' -o jsonpath='{.spec.containers[0].image}' 2>/dev/null)\" = 'nginx:1.25-alpine' ]"

pod_ready_via_sa() {
  local i
  for ((i = 0; i < 30; i++)); do
    if [ "$(kubectl get pod worker-app -n "$QUESTION_ID" -o jsonpath='{.status.containerStatuses[0].ready}' 2>/dev/null)" = "true" ] \
      && [ "$(kubectl get pod worker-app -n "$QUESTION_ID" -o jsonpath='{.spec.serviceAccountName}' 2>/dev/null)" = "ci-deploy" ] \
      && [ "$(kubectl get pod worker-app -n "$QUESTION_ID" -o jsonpath='{.spec.containers[0].name}' 2>/dev/null)" = "worker-app" ]; then
      return 0
    fi
    sleep 3
  done
  return 1
}
check_criterion "Pod 'worker-app' (name/container name kept, still ServiceAccount 'ci-deploy') reaches Running and Ready" \
  pod_ready_via_sa

print_score
