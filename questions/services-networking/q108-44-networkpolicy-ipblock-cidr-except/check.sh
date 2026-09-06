#!/usr/bin/env bash
# Spec-only checks, same rationale as every other NetworkPolicy question in
# this bank: this cluster's default CNI does not enforce NetworkPolicy, so
# only the object's spec is asserted.
set -uo pipefail

QUESTION_ID="q108-44-networkpolicy-ipblock-cidr-except${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "NetworkPolicy 'analytics-restrict-egress-cidr' exists in $QUESTION_ID" \
  resource_exists networkpolicy analytics-restrict-egress-cidr -n "$QUESTION_ID"

check_criterion "NetworkPolicy selects app=analytics with policyTypes [Egress]" \
  bash -c "[ \"\$(kubectl get networkpolicy analytics-restrict-egress-cidr -n '$QUESTION_ID' -o jsonpath='{.spec.podSelector.matchLabels.app}')\" = 'analytics' ] && \
    [ \"\$(kubectl get networkpolicy analytics-restrict-egress-cidr -n '$QUESTION_ID' -o jsonpath='{.spec.policyTypes}')\" = '[\"Egress\"]' ]"

check_criterion "Egress rule allows ipBlock cidr 10.0.0.0/8" \
  [ "$(kget networkpolicy analytics-restrict-egress-cidr '{.spec.egress[0].to[0].ipBlock.cidr}' -n "$QUESTION_ID")" = "10.0.0.0/8" ]

check_criterion "Egress rule's ipBlock excludes 10.0.5.0/24" \
  [ "$(kget networkpolicy analytics-restrict-egress-cidr '{.spec.egress[0].to[0].ipBlock.except[0]}' -n "$QUESTION_ID")" = "10.0.5.0/24" ]

print_score
