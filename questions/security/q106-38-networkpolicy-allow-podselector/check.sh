#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q106-38-networkpolicy-allow-podselector${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "NetworkPolicy 'billing-db-allow' exists, selects app=billing-db, and includes Ingress in policyTypes" \
  bash -c "
    kubectl get networkpolicy billing-db-allow -n '$QUESTION_ID' >/dev/null 2>&1 || exit 1
    [ \"\$(kubectl get networkpolicy billing-db-allow -n '$QUESTION_ID' -o jsonpath='{.spec.podSelector.matchLabels.app}')\" = 'billing-db' ] || exit 1
    kubectl get networkpolicy billing-db-allow -n '$QUESTION_ID' -o jsonpath='{.spec.policyTypes[*]}' | grep -qw Ingress
  "

check_criterion "NetworkPolicy's single ingress rule allows only from pods labeled app=billing-worker" \
  bash -c "
    kubectl get networkpolicy billing-db-allow -n '$QUESTION_ID' >/dev/null 2>&1 || exit 1
    [ \"\$(kubectl get networkpolicy billing-db-allow -n '$QUESTION_ID' -o jsonpath='{.spec.ingress[0].from[0].podSelector.matchLabels.app}')\" = 'billing-worker' ]
  "

print_score
