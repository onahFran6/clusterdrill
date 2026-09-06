#!/usr/bin/env bash
# Spec-only checks, same rationale as every other NetworkPolicy question in
# this bank (q108-14/16/17/26/29/31/32/39/44/47/48/50/51): this cluster's
# default CNI does not enforce NetworkPolicy, so only the object's spec is
# asserted.
set -uo pipefail

QUESTION_ID="q108-52-networkpolicy-same-namespace-only-ingress${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "NetworkPolicy 'internal-api-allow-same-namespace' exists in $QUESTION_ID" \
  resource_exists networkpolicy internal-api-allow-same-namespace -n "$QUESTION_ID"

check_criterion "NetworkPolicy selects app=internal-api" \
  [ "$(kget networkpolicy internal-api-allow-same-namespace '{.spec.podSelector.matchLabels.app}' -n "$QUESTION_ID")" = "internal-api" ]

check_criterion "NetworkPolicy policyTypes is exactly ['Ingress']" \
  [ "$(kget networkpolicy internal-api-allow-same-namespace '{.spec.policyTypes}' -n "$QUESTION_ID")" = '["Ingress"]' ]

# The exact shape being tested: a peer with only podSelector (same-namespace
# only), never a namespaceSelector (which would reach other namespaces too -
# see q108-16, the contrasting case).
check_criterion "ingress peer has podSelector but no namespaceSelector (same namespace only)" \
  bash -c "kubectl get networkpolicy internal-api-allow-same-namespace -n '$QUESTION_ID' -o json | \
    jq -e '.spec.ingress[0].from[0] | has(\"podSelector\") and (has(\"namespaceSelector\") | not)'"

check_criterion "podSelector peer is empty (matches every pod in the namespace)" \
  bash -c "kubectl get networkpolicy internal-api-allow-same-namespace -n '$QUESTION_ID' -o json | \
    jq -e '.spec.ingress[0].from[0].podSelector == {}'"

print_score
