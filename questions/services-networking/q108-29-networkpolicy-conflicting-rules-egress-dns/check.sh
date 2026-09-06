#!/usr/bin/env bash
# Spec-only checks, same rationale as q108-14: this cluster's default CNI
# does not enforce NetworkPolicy, so only the object's fields are asserted -
# a functional nslookup would pass even in the unsolved state here since
# nothing actually blocks the traffic at the network layer.
set -uo pipefail

QUESTION_ID="q108-29-networkpolicy-conflicting-rules-egress-dns${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

# "Exists" alone, or "the internal-api rule is unchanged" alone, would both
# trivially pass against setup.sh's own seeded policy before the candidate
# touches anything - so every criterion below is bundled with something only
# the fix (the new port-53/kube-system rule) can satisfy: either the exact
# egress-rule count (2, never 1) or the DNS rule's own fields directly.

check_criterion "NetworkPolicy has exactly two egress rules, the original TCP/8080-to-internal-api one plus one more" \
  bash -c "[ \"\$(kubectl get networkpolicy report-generator-egress -n '$QUESTION_ID' -o jsonpath='{.spec.egress[*].ports[0].port}' | wc -w | tr -d ' ')\" = '2' ] && \
    [ \"\$(kubectl get networkpolicy report-generator-egress -n '$QUESTION_ID' -o jsonpath='{.spec.egress[?(@.ports[0].port==8080)].to[0].podSelector.matchLabels.app}')\" = 'internal-api' ] && \
    [ \"\$(kubectl get networkpolicy report-generator-egress -n '$QUESTION_ID' -o jsonpath='{.spec.egress[?(@.ports[0].port==8080)].ports[0].protocol}')\" = 'TCP' ]"

check_criterion "NetworkPolicy has a second egress rule targeting kube-system by namespaceSelector" \
  [ "$(kget networkpolicy report-generator-egress '{.spec.egress[?(@.ports[0].port==53)].to[0].namespaceSelector.matchLabels.kubernetes\.io/metadata\.name}' -n "$QUESTION_ID")" = "kube-system" ]

check_criterion "DNS egress rule allows port 53 over both UDP and TCP" \
  bash -c "protocols=\"\$(kubectl get networkpolicy report-generator-egress -n '$QUESTION_ID' -o jsonpath='{.spec.egress[?(@.ports[0].port==53)].ports[*].protocol}')\"; \
    echo \"\$protocols\" | grep -qw UDP && echo \"\$protocols\" | grep -qw TCP"

check_criterion "DNS egress rule ports are non-empty and exactly 53 (no wider port range added)" \
  bash -c "ports=\"\$(kubectl get networkpolicy report-generator-egress -n '$QUESTION_ID' -o jsonpath='{.spec.egress[?(@.ports[0].port==53)].ports[*].port}')\"; \
    [ -n \"\$ports\" ] || exit 1; \
    for p in \$ports; do [ \"\$p\" = '53' ] || exit 1; done"

print_score
