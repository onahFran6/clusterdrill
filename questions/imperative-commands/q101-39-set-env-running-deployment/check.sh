#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q101-39-set-env-running-deployment${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Deployment 'report-worker' template has env FEATURE_FLAG=beta" \
  bash -c "
    kubectl get deployment report-worker -n '$QUESTION_ID' \
      -o jsonpath='{.spec.template.spec.containers[0].env}' 2>/dev/null \
      | grep -q '\"name\":\"FEATURE_FLAG\",\"value\":\"beta\"'
  "

check_criterion "Deployment 'report-worker' rollout completes with the new env var and the running pod actually resolves FEATURE_FLAG=beta" \
  bash -c "
    kubectl rollout status deployment/report-worker -n '$QUESTION_ID' --timeout=60s >/dev/null 2>&1 || exit 1
    POD=\$(newest_pod_name '$QUESTION_ID' app=report-worker)
    [ -n \"\$POD\" ] || exit 1
    kubectl exec -n '$QUESTION_ID' \"\$POD\" -- sh -c 'echo \$FEATURE_FLAG' 2>/dev/null | grep -qx 'beta'
  "

print_score
