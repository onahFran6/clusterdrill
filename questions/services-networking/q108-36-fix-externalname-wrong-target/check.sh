#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q108-36-fix-externalname-wrong-target${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Service 'legacy-api-svc' externalName fixed to api.internal.example.com, still type ExternalName" \
  bash -c "[ \"\$(kubectl get service legacy-api-svc -n '$QUESTION_ID' -o jsonpath='{.spec.externalName}')\" = 'api.internal.example.com' ] && \
    [ \"\$(kubectl get service legacy-api-svc -n '$QUESTION_ID' -o jsonpath='{.spec.type}')\" = 'ExternalName' ]"

print_score
