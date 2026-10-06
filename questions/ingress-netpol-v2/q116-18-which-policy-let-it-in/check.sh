#!/usr/bin/env bash
# Spec-only checks: this bank's supported-cluster contract does not
# guarantee a NetworkPolicy-enforcing CNI, so only each object's own fields
# are asserted here, never live traffic blocking.
set -uo pipefail

QUESTION_ID="q116-18-which-policy-let-it-in${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "NetworkPolicy 'db-debug' no longer exists" \
  bash -c "! kubectl get networkpolicy db-debug -n '$QUESTION_ID' >/dev/null 2>&1"

# setup.sh already leaves deny-all-ingress/db-from-api in their correct,
# untouched shape, so grading that alone would be trivially true before
# the candidate does anything. Bundle it with db-debug's removal so this
# criterion only starts passing once the candidate has actually acted.
check_criterion "'deny-all-ingress' and 'db-from-api' are unchanged AND 'db-debug' is gone" \
  bash -c "[ \"\$(kubectl get networkpolicy deny-all-ingress -n '$QUESTION_ID' -o jsonpath='{.spec.podSelector}')\" = '{}' ] && \
    [ \"\$(kubectl get networkpolicy deny-all-ingress -n '$QUESTION_ID' -o jsonpath='{.spec.policyTypes}')\" = '[\"Ingress\"]' ] && \
    [ \"\$(kubectl get networkpolicy db-from-api -n '$QUESTION_ID' -o jsonpath='{.spec.podSelector.matchLabels.app}')\" = 'db' ] && \
    [ \"\$(kubectl get networkpolicy db-from-api -n '$QUESTION_ID' -o jsonpath='{.spec.ingress[0].from[0].podSelector.matchLabels.app}')\" = 'api' ] && \
    ! kubectl get networkpolicy db-debug -n '$QUESTION_ID' >/dev/null 2>&1"

print_score
