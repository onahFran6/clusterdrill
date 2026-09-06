#!/usr/bin/env bash
# Spec-only checks, same rationale as q108-14: this cluster's default CNI
# does not enforce NetworkPolicy, so only the object's fields are asserted.
set -uo pipefail

QUESTION_ID="q108-17-networkpolicy-restrict-port${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

# "Exists" and "selectors unchanged" would trivially pass against setup.sh's
# own seeded, ports-less policy, so every criterion below requires the
# *ports restriction* specifically - none can be satisfied unsolved.

check_criterion "Ingress rule restricts to exactly one port" \
  [ "$(kget networkpolicy admin-panel-ingress '{.spec.ingress[0].ports[*].port}' -n "$QUESTION_ID" | wc -w | tr -d ' ')" = "1" ]

check_criterion "Ingress rule allows TCP port 8443 only" \
  bash -c "[ \"\$(kubectl get networkpolicy admin-panel-ingress -n '$QUESTION_ID' -o jsonpath='{.spec.ingress[0].ports[0].port}')\" = '8443' ] && \
    [ \"\$(kubectl get networkpolicy admin-panel-ingress -n '$QUESTION_ID' -o jsonpath='{.spec.ingress[0].ports[0].protocol}')\" = 'TCP' ]"

check_criterion "podSelector/from-selector kept intact while ports were added" \
  bash -c "[ \"\$(kubectl get networkpolicy admin-panel-ingress -n '$QUESTION_ID' -o jsonpath='{.spec.podSelector.matchLabels.app}')\" = 'admin-panel' ] && \
    [ \"\$(kubectl get networkpolicy admin-panel-ingress -n '$QUESTION_ID' -o jsonpath='{.spec.ingress[0].from[0].podSelector.matchLabels.app}')\" = 'ops-console' ] && \
    [ \"\$(kubectl get networkpolicy admin-panel-ingress -n '$QUESTION_ID' -o jsonpath='{.spec.ingress[0].ports[0].port}')\" = '8443' ]"

print_score
