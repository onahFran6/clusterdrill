#!/usr/bin/env bash
# Spec-only checks, same rationale as q108-14: this cluster's default CNI
# does not enforce NetworkPolicy, so only the object's fields are asserted.
set -uo pipefail

QUESTION_ID="q108-15-networkpolicy-allow-egress-to-pods${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "NetworkPolicy 'report-generator-restrict-egress' exists in $QUESTION_ID" \
  resource_exists networkpolicy report-generator-restrict-egress -n "$QUESTION_ID"

check_criterion "NetworkPolicy podSelector targets app=report-generator" \
  [ "$(kget networkpolicy report-generator-restrict-egress '{.spec.podSelector.matchLabels.app}' -n "$QUESTION_ID")" = "report-generator" ]

check_criterion "NetworkPolicy policyTypes includes 'Egress'" \
  bash -c "kubectl get networkpolicy report-generator-restrict-egress -n '$QUESTION_ID' \
    -o jsonpath='{.spec.policyTypes[*]}' | grep -qw Egress"

check_criterion "NetworkPolicy egress rule allows to app=metrics-store" \
  [ "$(kget networkpolicy report-generator-restrict-egress '{.spec.egress[0].to[0].podSelector.matchLabels.app}' -n "$QUESTION_ID")" = "metrics-store" ]

check_criterion "NetworkPolicy egress rule restricts to TCP port 9090" \
  bash -c "[ \"\$(kubectl get networkpolicy report-generator-restrict-egress -n '$QUESTION_ID' -o jsonpath='{.spec.egress[0].ports[0].port}')\" = '9090' ] && \
    [ \"\$(kubectl get networkpolicy report-generator-restrict-egress -n '$QUESTION_ID' -o jsonpath='{.spec.egress[0].ports[0].protocol}')\" = 'TCP' ]"

print_score
