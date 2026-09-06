#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q108-37-fix-nodeport-out-of-range${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Service 'billing-svc' exists in $QUESTION_ID" \
  resource_exists service billing-svc -n "$QUESTION_ID"

check_criterion "Service 'billing-svc' is type NodePort" \
  [ "$(kget service billing-svc '{.spec.type}' -n "$QUESTION_ID")" = "NodePort" ]

check_criterion "Service 'billing-svc' listens on port 80 forwarding to 80" \
  bash -c "[ \"\$(kubectl get service billing-svc -n '$QUESTION_ID' -o jsonpath='{.spec.ports[0].port}')\" = '80' ] && \
    [ \"\$(kubectl get service billing-svc -n '$QUESTION_ID' -o jsonpath='{.spec.ports[0].targetPort}')\" = '80' ]"

check_criterion "Service 'billing-svc' nodePort fixed to the valid value 30090" \
  [ "$(kget service billing-svc '{.spec.ports[0].nodePort}' -n "$QUESTION_ID")" = "30090" ]

print_score
