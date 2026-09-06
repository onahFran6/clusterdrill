#!/usr/bin/env bash
# Spec-only checks, same rationale as q108-14: this cluster's default CNI
# does not enforce NetworkPolicy, so only the object's fields are asserted.
set -uo pipefail

QUESTION_ID="q108-16-networkpolicy-namespace-selector${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "NetworkPolicy 'shared-cache-allow-platform-ns' exists in $QUESTION_ID" \
  resource_exists networkpolicy shared-cache-allow-platform-ns -n "$QUESTION_ID"

check_criterion "NetworkPolicy podSelector targets app=shared-cache" \
  [ "$(kget networkpolicy shared-cache-allow-platform-ns '{.spec.podSelector.matchLabels.app}' -n "$QUESTION_ID")" = "shared-cache" ]

check_criterion "NetworkPolicy policyTypes includes 'Ingress'" \
  bash -c "kubectl get networkpolicy shared-cache-allow-platform-ns -n '$QUESTION_ID' \
    -o jsonpath='{.spec.policyTypes[*]}' | grep -qw Ingress"

check_criterion "NetworkPolicy ingress rule uses namespaceSelector for team=platform" \
  [ "$(kget networkpolicy shared-cache-allow-platform-ns '{.spec.ingress[0].from[0].namespaceSelector.matchLabels.team}' -n "$QUESTION_ID")" = "platform" ]

check_criterion "NetworkPolicy ingress rule does not narrow by podSelector (whole namespace allowed)" \
  bash -c "kubectl get networkpolicy shared-cache-allow-platform-ns -n '$QUESTION_ID' >/dev/null 2>&1 && \
    [ -n \"\$(kubectl get networkpolicy shared-cache-allow-platform-ns -n '$QUESTION_ID' -o jsonpath='{.spec.ingress[0].from[0].namespaceSelector}')\" ] && \
    [ -z \"\$(kubectl get networkpolicy shared-cache-allow-platform-ns -n '$QUESTION_ID' -o jsonpath='{.spec.ingress[0].from[0].podSelector}')\" ]"

check_criterion "NetworkPolicy ingress rule restricts to TCP port 6379" \
  bash -c "[ \"\$(kubectl get networkpolicy shared-cache-allow-platform-ns -n '$QUESTION_ID' -o jsonpath='{.spec.ingress[0].ports[0].port}')\" = '6379' ] && \
    [ \"\$(kubectl get networkpolicy shared-cache-allow-platform-ns -n '$QUESTION_ID' -o jsonpath='{.spec.ingress[0].ports[0].protocol}')\" = 'TCP' ]"

print_score
