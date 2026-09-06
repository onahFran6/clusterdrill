#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q101-50-scale-down-to-free-resourcequota${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Deployment 'legacy-batch' was scaled down to 1 replica (not deleted)" \
  bash -c "
    kubectl get deployment legacy-batch -n '$QUESTION_ID' >/dev/null 2>&1 || exit 1
    [ \"\$(kubectl get deployment legacy-batch -n '$QUESTION_ID' -o jsonpath='{.spec.replicas}' 2>/dev/null)\" = '1' ]
  "

report_gen_ready() {
  local i
  for ((i = 0; i < 20; i++)); do
    if [ "$(kubectl get pod report-gen -n "$QUESTION_ID" -o jsonpath='{.spec.containers[0].image}' 2>/dev/null)" = "busybox:1.36" ] \
      && [ "$(kubectl get pod report-gen -n "$QUESTION_ID" -o jsonpath='{.status.containerStatuses[0].ready}' 2>/dev/null)" = "true" ]; then
      return 0
    fi
    sleep 3
  done
  return 1
}
check_criterion "Pod 'report-gen' exists, image busybox:1.36, and reaches Running/Ready" \
  report_gen_ready

print_score
