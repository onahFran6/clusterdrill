#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q108-34-service-type-loadbalancer-basic${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Service 'webshop-svc' exists in $QUESTION_ID" \
  resource_exists service webshop-svc -n "$QUESTION_ID"

check_criterion "Service 'webshop-svc' is type LoadBalancer" \
  [ "$(kget service webshop-svc '{.spec.type}' -n "$QUESTION_ID")" = "LoadBalancer" ]

check_criterion "Service 'webshop-svc' selects app=webshop" \
  [ "$(kget service webshop-svc '{.spec.selector.app}' -n "$QUESTION_ID")" = "webshop" ]

check_criterion "Service 'webshop-svc' listens on port 80 forwarding to 80" \
  bash -c "[ \"\$(kubectl get service webshop-svc -n '$QUESTION_ID' -o jsonpath='{.spec.ports[0].port}')\" = '80' ] && \
    [ \"\$(kubectl get service webshop-svc -n '$QUESTION_ID' -o jsonpath='{.spec.ports[0].targetPort}')\" = '80' ]"

print_score
