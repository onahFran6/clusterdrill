#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q108-43-service-internaltrafficpolicy-local${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

# "still type ClusterIP" is already true right after setup.sh (only
# internalTrafficPolicy is unset there), so it is bundled with the actual
# fix below to keep the unsolved state at 0.
check_criterion "Service 'metrics-sidecar-svc' internalTrafficPolicy set to Local, still type ClusterIP" \
  bash -c "[ \"\$(kubectl get service metrics-sidecar-svc -n '$QUESTION_ID' -o jsonpath='{.spec.internalTrafficPolicy}')\" = 'Local' ] && \
    [ \"\$(kubectl get service metrics-sidecar-svc -n '$QUESTION_ID' -o jsonpath='{.spec.type}')\" = 'ClusterIP' ]"

print_score
