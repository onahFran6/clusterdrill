#!/usr/bin/env bash
# NetworkPolicy enforcement is not verified live here: this cluster's default
# CNI (minikube's bridge/kindnet-style networking) does not enforce
# NetworkPolicy objects, only the API server accepts and stores them. Every
# criterion below asserts the policy's *spec* is correct (the part a CKAD
# grader/exam checks too), not that traffic is actually blocked/allowed.
set -uo pipefail

QUESTION_ID="q108-14-networkpolicy-allow-ingress-from-pods${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "NetworkPolicy 'payments-api-allow-frontend' exists in $QUESTION_ID" \
  resource_exists networkpolicy payments-api-allow-frontend -n "$QUESTION_ID"

check_criterion "NetworkPolicy podSelector targets app=payments-api" \
  [ "$(kget networkpolicy payments-api-allow-frontend '{.spec.podSelector.matchLabels.app}' -n "$QUESTION_ID")" = "payments-api" ]

check_criterion "NetworkPolicy policyTypes includes 'Ingress'" \
  bash -c "kubectl get networkpolicy payments-api-allow-frontend -n '$QUESTION_ID' \
    -o jsonpath='{.spec.policyTypes[*]}' | grep -qw Ingress"

check_criterion "NetworkPolicy ingress rule allows from app=web-frontend" \
  [ "$(kget networkpolicy payments-api-allow-frontend '{.spec.ingress[0].from[0].podSelector.matchLabels.app}' -n "$QUESTION_ID")" = "web-frontend" ]

check_criterion "NetworkPolicy ingress rule restricts to TCP port 8080" \
  bash -c "[ \"\$(kubectl get networkpolicy payments-api-allow-frontend -n '$QUESTION_ID' -o jsonpath='{.spec.ingress[0].ports[0].port}')\" = '8080' ] && \
    [ \"\$(kubectl get networkpolicy payments-api-allow-frontend -n '$QUESTION_ID' -o jsonpath='{.spec.ingress[0].ports[0].protocol}')\" = 'TCP' ]"

print_score
