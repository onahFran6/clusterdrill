#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q106-18-networkpolicy-default-deny-ingress${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "NetworkPolicy 'default-deny-ingress' exists in $QUESTION_ID" \
  resource_exists networkpolicy default-deny-ingress -n "$QUESTION_ID"

check_criterion "NetworkPolicy selects all pods (empty podSelector)" \
  [ "$(kget networkpolicy default-deny-ingress '{.spec.podSelector}' -n "$QUESTION_ID")" = "{}" ]

check_criterion "NetworkPolicy policyTypes includes 'Ingress'" \
  bash -c "kubectl get networkpolicy default-deny-ingress -n '$QUESTION_ID' \
    -o jsonpath='{.spec.policyTypes[*]}' | grep -qw Ingress"

check_criterion "NetworkPolicy defines no ingress rules (deny-all)" \
  bash -c "kubectl get networkpolicy default-deny-ingress -n '$QUESTION_ID' >/dev/null 2>&1 && \
    [ -z \"\$(kubectl get networkpolicy default-deny-ingress -n '$QUESTION_ID' -o jsonpath='{.spec.ingress}' 2>/dev/null)\" ]"

print_score
