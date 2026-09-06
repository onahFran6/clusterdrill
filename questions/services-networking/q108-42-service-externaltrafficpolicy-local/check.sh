#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q108-42-service-externaltrafficpolicy-local${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

# "still type NodePort" is already true right after setup.sh (only
# externalTrafficPolicy is unset there), so it is bundled with the actual
# fix below to keep the unsolved state at 0.
check_criterion "Service 'edge-gateway-svc' externalTrafficPolicy set to Local, still type NodePort" \
  bash -c "[ \"\$(kubectl get service edge-gateway-svc -n '$QUESTION_ID' -o jsonpath='{.spec.externalTrafficPolicy}')\" = 'Local' ] && \
    [ \"\$(kubectl get service edge-gateway-svc -n '$QUESTION_ID' -o jsonpath='{.spec.type}')\" = 'NodePort' ]"

print_score
