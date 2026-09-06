#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q108-23-expose-deployment-via-kubectl-expose${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Service 'billing-worker-svc' exists and is type ClusterIP" \
  bash -c "[ \"\$(kubectl get service billing-worker-svc -n '$QUESTION_ID' -o jsonpath='{.spec.type}' 2>/dev/null)\" = 'ClusterIP' ]"

check_criterion "Service port 443 maps to targetPort 8443" \
  bash -c "kubectl get service billing-worker-svc -n '$QUESTION_ID' -o jsonpath='{.spec.ports[?(@.port==443)].targetPort}' 2>/dev/null | grep -qx '8443'"

check_criterion "Service has ready endpoints equal to the number of running pods" \
  bash -c "
    running=\$(kubectl get pods -n '$QUESTION_ID' -l app=billing-worker --field-selector=status.phase=Running -o name 2>/dev/null | wc -l | tr -d ' ')
    endpoints=\$(kubectl get endpoints billing-worker-svc -n '$QUESTION_ID' -o jsonpath='{.subsets[*].addresses[*].ip}' 2>/dev/null | wc -w | tr -d ' ')
    [ \"\$running\" -gt 0 ] && [ \"\$endpoints\" = \"\$running\" ]
  "

print_score
