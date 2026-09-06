#!/usr/bin/env bash
# Spec-only checks, same rationale as every other NetworkPolicy question in
# this bank (q108-14/16/17/26/29/31/32/39/44/47/48/50): this cluster's
# default CNI does not enforce NetworkPolicy, so only the objects' specs
# are asserted.
set -uo pipefail

QUESTION_ID="q108-51-networkpolicy-additive-allow-overrides-deny${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "NetworkPolicy 'api-allow-all-ingress' exists in $QUESTION_ID" \
  resource_exists networkpolicy api-allow-all-ingress -n "$QUESTION_ID"

check_criterion "api-allow-all-ingress selects app=api" \
  [ "$(kget networkpolicy api-allow-all-ingress '{.spec.podSelector.matchLabels.app}' -n "$QUESTION_ID")" = "api" ]

check_criterion "api-allow-all-ingress policyTypes is exactly ['Ingress']" \
  [ "$(kget networkpolicy api-allow-all-ingress '{.spec.policyTypes}' -n "$QUESTION_ID")" = '["Ingress"]' ]

check_criterion "api-allow-all-ingress has exactly one unrestricted ingress rule (allows all)" \
  bash -c "kubectl get networkpolicy api-allow-all-ingress -n '$QUESTION_ID' -o json | jq -e '.spec.ingress == [{}]'"

print_score
