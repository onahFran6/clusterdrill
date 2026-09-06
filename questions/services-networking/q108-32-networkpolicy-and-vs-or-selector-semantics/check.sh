#!/usr/bin/env bash
# Spec-only checks, same rationale as q108-14/16/26/29/31: this cluster's
# default CNI does not enforce NetworkPolicy, so only the object's spec is
# asserted - a live "can it connect" test would pass identically whether or
# not the OR-vs-AND bug is fixed, since nothing actually blocks traffic at
# the network layer here.
set -uo pipefail

QUESTION_ID="q108-32-networkpolicy-and-vs-or-selector-semantics${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

NP_NAME="allow-trusted-platform-clients"

# Compute FIXED once: the unsolved policy has two SEPARATE `from` entries
# (from[0]=podSelector only, from[1]=namespaceSelector only), so from[1] is
# non-empty and from[0] lacks a namespaceSelector. The fix merges both
# fields onto the single from[0] entry and leaves no from[1] at all.
FROM1="$(kubectl get networkpolicy "$NP_NAME" -n "$QUESTION_ID" -o jsonpath='{.spec.ingress[0].from[1]}' 2>/dev/null)"
POD_ROLE="$(kubectl get networkpolicy "$NP_NAME" -n "$QUESTION_ID" -o jsonpath='{.spec.ingress[0].from[0].podSelector.matchLabels.role}' 2>/dev/null)"
NS_TEAM="$(kubectl get networkpolicy "$NP_NAME" -n "$QUESTION_ID" -o jsonpath='{.spec.ingress[0].from[0].namespaceSelector.matchLabels.team}' 2>/dev/null)"

if [ -z "$FROM1" ] && [ "$POD_ROLE" = "trusted-client" ] && [ "$NS_TEAM" = "platform" ]; then
  FIXED=0
else
  FIXED=1
fi

# Every criterion below is gated on $FIXED so none of them can score in the
# unsolved state: podSelector/policyTypes/port are already correct right
# after setup.sh, so without this shared guard those alone would trivially
# pass before the candidate touches anything, which the "unsolved must
# score 0" gate forbids.

check_criterion "Ingress from-list has exactly one entry combining podSelector AND namespaceSelector (AND semantics, not two OR'd entries)" \
  bash -c "
    [ '$FIXED' = '0' ] && \
    kubectl get networkpolicy '$NP_NAME' -n '$QUESTION_ID' >/dev/null 2>&1 && \
    [ \"\$(kubectl get networkpolicy '$NP_NAME' -n '$QUESTION_ID' -o jsonpath='{.spec.ingress[0].from[0].podSelector.matchLabels.role}')\" = 'trusted-client' ] && \
    [ \"\$(kubectl get networkpolicy '$NP_NAME' -n '$QUESTION_ID' -o jsonpath='{.spec.ingress[0].from[0].namespaceSelector.matchLabels.team}')\" = 'platform' ] && \
    [ -z \"\$(kubectl get networkpolicy '$NP_NAME' -n '$QUESTION_ID' -o jsonpath='{.spec.ingress[0].from[1]}')\" ]
  "

check_criterion "Fix applied AND NetworkPolicy still targets app=payment-api pods" \
  bash -c "
    [ '$FIXED' = '0' ] && \
    [ \"\$(kubectl get networkpolicy '$NP_NAME' -n '$QUESTION_ID' -o jsonpath='{.spec.podSelector.matchLabels.app}')\" = 'payment-api' ]
  "

check_criterion "Fix applied AND policyTypes remains exactly ['Ingress']" \
  bash -c "
    [ '$FIXED' = '0' ] && \
    [ \"\$(kubectl get networkpolicy '$NP_NAME' -n '$QUESTION_ID' -o jsonpath='{.spec.policyTypes}')\" = '[\"Ingress\"]' ]
  "

check_criterion "Fix applied AND ingress rule still restricts to TCP port 8443 with no extra ingress rules added" \
  bash -c "
    [ '$FIXED' = '0' ] && \
    [ \"\$(kubectl get networkpolicy '$NP_NAME' -n '$QUESTION_ID' -o jsonpath='{.spec.ingress[0].ports[0].port}')\" = '8443' ] && \
    [ \"\$(kubectl get networkpolicy '$NP_NAME' -n '$QUESTION_ID' -o jsonpath='{.spec.ingress[0].ports[0].protocol}')\" = 'TCP' ] && \
    [ -z \"\$(kubectl get networkpolicy '$NP_NAME' -n '$QUESTION_ID' -o jsonpath='{.spec.ingress[1]}')\" ]
  "

check_criterion "Deployment 'payment-api' left untouched by the fix" \
  bash -c "
    [ '$FIXED' = '0' ] && \
    kubectl get deployment payment-api -n '$QUESTION_ID' >/dev/null 2>&1 && \
    [ \"\$(kubectl get deployment payment-api -n '$QUESTION_ID' -o jsonpath='{.spec.template.metadata.labels.app}')\" = 'payment-api' ]
  "

print_score
