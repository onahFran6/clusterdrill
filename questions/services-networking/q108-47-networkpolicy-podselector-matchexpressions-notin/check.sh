#!/usr/bin/env bash
# Spec-only checks, same rationale as every other NetworkPolicy question in
# this bank: this cluster's default CNI does not enforce NetworkPolicy, so
# only the object's spec is asserted.
set -uo pipefail

QUESTION_ID="q108-47-networkpolicy-podselector-matchexpressions-notin${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

NP_NAME="worker-pool-restrict-egress"

KEY="$(kget networkpolicy "$NP_NAME" '{.spec.egress[0].to[0].podSelector.matchExpressions[0].key}' -n "$QUESTION_ID")"
OP="$(kget networkpolicy "$NP_NAME" '{.spec.egress[0].to[0].podSelector.matchExpressions[0].operator}' -n "$QUESTION_ID")"
VAL="$(kget networkpolicy "$NP_NAME" '{.spec.egress[0].to[0].podSelector.matchExpressions[0].values[0]}' -n "$QUESTION_ID")"
OLD_MATCHLABEL="$(kget networkpolicy "$NP_NAME" '{.spec.egress[0].to[0].podSelector.matchLabels.tier}' -n "$QUESTION_ID")"

if [ "$KEY" = "tier" ] && [ "$OP" = "NotIn" ] && [ "$VAL" = "legacy" ] && [ -z "$OLD_MATCHLABEL" ]; then
  FIXED=0
else
  FIXED=1
fi

check_criterion "Egress peer podSelector rewritten to matchExpressions: tier NotIn [legacy] (matchLabels removed)" \
  [ "$FIXED" = "0" ]

check_criterion "Fix applied AND NetworkPolicy still selects app=worker-pool with policyTypes [Egress]" \
  bash -c "[ '$FIXED' = '0' ] && \
    [ \"\$(kubectl get networkpolicy '$NP_NAME' -n '$QUESTION_ID' -o jsonpath='{.spec.podSelector.matchLabels.app}')\" = 'worker-pool' ] && \
    [ \"\$(kubectl get networkpolicy '$NP_NAME' -n '$QUESTION_ID' -o jsonpath='{.spec.policyTypes}')\" = '[\"Egress\"]' ]"

check_criterion "Fix applied AND egress rule still restricts to TCP port 8080, no extra egress rules" \
  bash -c "[ '$FIXED' = '0' ] && \
    [ \"\$(kubectl get networkpolicy '$NP_NAME' -n '$QUESTION_ID' -o jsonpath='{.spec.egress[0].ports[0].port}')\" = '8080' ] && \
    [ \"\$(kubectl get networkpolicy '$NP_NAME' -n '$QUESTION_ID' -o jsonpath='{.spec.egress[0].ports[0].protocol}')\" = 'TCP' ] && \
    [ -z \"\$(kubectl get networkpolicy '$NP_NAME' -n '$QUESTION_ID' -o jsonpath='{.spec.egress[1]}')\" ]"

print_score
