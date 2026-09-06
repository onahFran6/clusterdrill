#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q108-02-multiport-service${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Service 'web-app-svc' exists in $QUESTION_ID" \
  resource_exists service web-app-svc -n "$QUESTION_ID"

check_criterion "Service 'web-app-svc' is type ClusterIP" \
  [ "$(kget service web-app-svc '{.spec.type}' -n "$QUESTION_ID")" = "ClusterIP" ]

check_criterion "Service 'web-app-svc' selects app=web-app" \
  [ "$(kget service web-app-svc '{.spec.selector.app}' -n "$QUESTION_ID")" = "web-app" ]

check_criterion "Service 'web-app-svc' exposes exactly 2 ports" \
  [ "$(kget service web-app-svc '{.spec.ports[*].name}' -n "$QUESTION_ID" | wc -w | tr -d ' ')" = "2" ]

check_criterion "Service 'web-app-svc' port 'http' is 80 -> 80" \
  bash -c "[ \"\$(kubectl get service web-app-svc -n '$QUESTION_ID' -o jsonpath='{.spec.ports[?(@.name==\"http\")].port}')\" = '80' ] && \
    [ \"\$(kubectl get service web-app-svc -n '$QUESTION_ID' -o jsonpath='{.spec.ports[?(@.name==\"http\")].targetPort}')\" = '80' ]"

check_criterion "Service 'web-app-svc' port 'https' is 443 -> 8443" \
  bash -c "[ \"\$(kubectl get service web-app-svc -n '$QUESTION_ID' -o jsonpath='{.spec.ports[?(@.name==\"https\")].port}')\" = '443' ] && \
    [ \"\$(kubectl get service web-app-svc -n '$QUESTION_ID' -o jsonpath='{.spec.ports[?(@.name==\"https\")].targetPort}')\" = '8443' ]"

print_score
