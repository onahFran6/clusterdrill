#!/usr/bin/env bash
# Spec-only checks, same rationale as every other NetworkPolicy question in
# this bank (q108-14/16/17/26/29/31/32): this cluster's default CNI does not
# enforce NetworkPolicy, so only the object's spec is asserted.
set -uo pipefail

QUESTION_ID="q108-39-networkpolicy-default-deny-all-egress${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "NetworkPolicy 'worker-deny-egress' exists in $QUESTION_ID" \
  resource_exists networkpolicy worker-deny-egress -n "$QUESTION_ID"

check_criterion "NetworkPolicy selects app=worker" \
  [ "$(kget networkpolicy worker-deny-egress '{.spec.podSelector.matchLabels.app}' -n "$QUESTION_ID")" = "worker" ]

check_criterion "NetworkPolicy policyTypes is exactly ['Egress']" \
  [ "$(kget networkpolicy worker-deny-egress '{.spec.policyTypes}' -n "$QUESTION_ID")" = '["Egress"]' ]

# "-z egress" alone would be vacuously true against a nonexistent object too
# (kget prints nothing on a missing resource) - bundled with resource_exists
# so it cannot score before the NetworkPolicy is actually created.
check_criterion "NetworkPolicy exists and defines no egress rules (denies all)" \
  bash -c "kubectl get networkpolicy worker-deny-egress -n '$QUESTION_ID' >/dev/null 2>&1 && \
    [ -z \"\$(kubectl get networkpolicy worker-deny-egress -n '$QUESTION_ID' -o jsonpath='{.spec.egress}')\" ]"

print_score
