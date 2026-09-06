#!/usr/bin/env bash
# NetworkPolicy enforcement is not verified live here: this cluster's default
# CNI (minikube's bridge/kindnet-style networking, no Calico/Cilium/etc.)
# does not enforce NetworkPolicy objects, only the API server accepts and
# stores them - same rationale as every other NetworkPolicy question in this
# bank (q108-14/16/17/26). A live TCP-connect test would pass identically
# whether or not the typo is fixed, since nothing in this cluster actually
# blocks the traffic, which would violate the "unsolved state scores 0"
# gate. Every criterion below instead asserts the policies' *spec* is
# correct - the part a CKAD exam grader checks too.
#
# Both criteria below repeat the same "from-label is exactly tier=api" guard
# so that NEITHER one can score in the unsolved state: everything else
# asserted (podSelector/policyTypes/rule shape/port on both policies, both
# Deployments existing with their labels intact) is already true right
# after setup.sh, so without that shared guard this would trivially score
# points before the candidate does anything, which the "unsolved must score
# 0" gate forbids.
set -uo pipefail

QUESTION_ID="q108-31-networkpolicy-label-selector-typo-cascading${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

FROM_LABELS="$(kubectl get networkpolicy allow-api-to-cache -n "$QUESTION_ID" -o jsonpath='{.spec.ingress[0].from[0].podSelector.matchLabels}' 2>/dev/null)"
if [ "$FROM_LABELS" = '{"tier":"api"}' ]; then
  TYPO_FIXED=0
else
  TYPO_FIXED=1
fi

check_criterion "NetworkPolicy 'allow-api-to-cache' ingress rule correctly allows only tier=api on TCP/6379" \
  bash -c "
    [ '$TYPO_FIXED' = '0' ] && \
    kubectl get networkpolicy allow-api-to-cache -n '$QUESTION_ID' >/dev/null 2>&1 && \
    [ \"\$(kubectl get networkpolicy allow-api-to-cache -n '$QUESTION_ID' -o jsonpath='{.spec.podSelector.matchLabels.tier}')\" = 'cache' ] && \
    [ \"\$(kubectl get networkpolicy allow-api-to-cache -n '$QUESTION_ID' -o jsonpath='{.spec.policyTypes}')\" = '[\"Ingress\"]' ] && \
    [ -z \"\$(kubectl get networkpolicy allow-api-to-cache -n '$QUESTION_ID' -o jsonpath='{.spec.ingress[1]}')\" ] && \
    [ -z \"\$(kubectl get networkpolicy allow-api-to-cache -n '$QUESTION_ID' -o jsonpath='{.spec.ingress[0].from[1]}')\" ] && \
    [ \"\$(kubectl get networkpolicy allow-api-to-cache -n '$QUESTION_ID' -o jsonpath='{.spec.ingress[0].ports[0].port}')\" = '6379' ] && \
    [ \"\$(kubectl get networkpolicy allow-api-to-cache -n '$QUESTION_ID' -o jsonpath='{.spec.ingress[0].ports[0].protocol}')\" = 'TCP' ]
  "

# default-deny-cache-ingress and both Deployments being intact is, on its
# own, already true right after setup.sh - so this criterion also requires
# the typo fix ($TYPO_FIXED, computed above) before it can pass, guaranteeing
# the unsolved state scores 0 on both criteria, not just the first.
check_criterion "Typo fixed AND NetworkPolicy 'default-deny-cache-ingress' plus both Deployments remain unmodified" \
  bash -c "
    [ '$TYPO_FIXED' = '0' ] && \
    kubectl get networkpolicy default-deny-cache-ingress -n '$QUESTION_ID' >/dev/null 2>&1 && \
    [ \"\$(kubectl get networkpolicy default-deny-cache-ingress -n '$QUESTION_ID' -o jsonpath='{.spec.podSelector.matchLabels.tier}')\" = 'cache' ] && \
    [ \"\$(kubectl get networkpolicy default-deny-cache-ingress -n '$QUESTION_ID' -o jsonpath='{.spec.policyTypes}')\" = '[\"Ingress\"]' ] && \
    [ -z \"\$(kubectl get networkpolicy default-deny-cache-ingress -n '$QUESTION_ID' -o jsonpath='{.spec.ingress}')\" ] && \
    kubectl get deployment cache-layer -n '$QUESTION_ID' >/dev/null 2>&1 && \
    kubectl get deployment api-layer -n '$QUESTION_ID' >/dev/null 2>&1 && \
    [ \"\$(kubectl get deployment cache-layer -n '$QUESTION_ID' -o jsonpath='{.spec.template.metadata.labels.tier}')\" = 'cache' ] && \
    [ \"\$(kubectl get deployment api-layer -n '$QUESTION_ID' -o jsonpath='{.spec.template.metadata.labels.tier}')\" = 'api' ]
  "

print_score
