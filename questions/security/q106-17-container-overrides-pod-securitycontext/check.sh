#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q106-17-container-overrides-pod-securitycontext${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Pod 'mixed-uid' exists in $QUESTION_ID" \
  resource_exists pod mixed-uid -n "$QUESTION_ID"

check_criterion "Pod 'mixed-uid' pod-level securityContext.runAsUser is 1000" \
  [ "$(kget pod mixed-uid '{.spec.securityContext.runAsUser}' -n "$QUESTION_ID")" = "1000" ]

check_criterion "Container 'special' overrides runAsUser to 2000" \
  bash -c "kubectl get pod mixed-uid -n '$QUESTION_ID' \
    -o jsonpath='{.spec.containers[?(@.name==\"special\")].securityContext.runAsUser}' | grep -qx 2000"

check_criterion "Container 'standard' has no container-level runAsUser override" \
  bash -c "kubectl get pod mixed-uid -n '$QUESTION_ID' >/dev/null 2>&1 && \
    [ -z \"\$(kubectl get pod mixed-uid -n '$QUESTION_ID' -o jsonpath='{.spec.containers[?(@.name==\"standard\")].securityContext.runAsUser}' 2>/dev/null)\" ]"

kubectl wait --for=condition=Ready pod/mixed-uid -n "$QUESTION_ID" --timeout=30s >/dev/null 2>&1

check_criterion "Pod 'mixed-uid' reaches Running" \
  [ "$(kget pod mixed-uid '{.status.phase}' -n "$QUESTION_ID")" = "Running" ]

print_score
