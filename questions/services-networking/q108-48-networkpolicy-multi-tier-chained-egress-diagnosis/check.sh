#!/usr/bin/env bash
# Spec-only checks, same rationale as every other NetworkPolicy question in
# this bank: this cluster's default CNI does not enforce NetworkPolicy, so
# only the object's spec is asserted.
set -uo pipefail

QUESTION_ID="q108-48-networkpolicy-multi-tier-chained-egress-diagnosis${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

NP_NAME="backend-to-database-egress"

TIER="$(kget networkpolicy "$NP_NAME" '{.spec.egress[0].to[0].podSelector.matchLabels.tier}' -n "$QUESTION_ID")"
if [ "$TIER" = "database" ]; then
  FIXED=0
else
  FIXED=1
fi

check_criterion "NetworkPolicy 'backend-to-database-egress' egress podSelector typo fixed to tier=database" \
  [ "$FIXED" = "0" ]

check_criterion "Fix applied AND 'backend-to-database-egress' still selects tier=backend, policyTypes [Egress], port 5432/TCP" \
  bash -c "[ '$FIXED' = '0' ] && \
    [ \"\$(kubectl get networkpolicy '$NP_NAME' -n '$QUESTION_ID' -o jsonpath='{.spec.podSelector.matchLabels.tier}')\" = 'backend' ] && \
    [ \"\$(kubectl get networkpolicy '$NP_NAME' -n '$QUESTION_ID' -o jsonpath='{.spec.policyTypes}')\" = '[\"Egress\"]' ] && \
    [ \"\$(kubectl get networkpolicy '$NP_NAME' -n '$QUESTION_ID' -o jsonpath='{.spec.egress[0].ports[0].port}')\" = '5432' ] && \
    [ \"\$(kubectl get networkpolicy '$NP_NAME' -n '$QUESTION_ID' -o jsonpath='{.spec.egress[0].ports[0].protocol}')\" = 'TCP' ]"

check_criterion "Fix applied AND 'frontend-to-backend-egress' left untouched (tier=frontend -> tier=backend, port 8080)" \
  bash -c "[ '$FIXED' = '0' ] && \
    [ \"\$(kubectl get networkpolicy frontend-to-backend-egress -n '$QUESTION_ID' -o jsonpath='{.spec.podSelector.matchLabels.tier}')\" = 'frontend' ] && \
    [ \"\$(kubectl get networkpolicy frontend-to-backend-egress -n '$QUESTION_ID' -o jsonpath='{.spec.egress[0].to[0].podSelector.matchLabels.tier}')\" = 'backend' ] && \
    [ \"\$(kubectl get networkpolicy frontend-to-backend-egress -n '$QUESTION_ID' -o jsonpath='{.spec.egress[0].ports[0].port}')\" = '8080' ]"

check_criterion "Fix applied AND all three Deployments (frontend/backend/database) remain intact" \
  bash -c "[ '$FIXED' = '0' ] && \
    kubectl get deployment frontend backend database -n '$QUESTION_ID' >/dev/null 2>&1"

print_score
