#!/usr/bin/env bash
# Spec-only checks, same rationale as q108-14/q108-16: this cluster's default
# CNI does not enforce NetworkPolicy, so only the object's fields are
# asserted, not live traffic blocking.
set -uo pipefail

QUESTION_ID="q108-26-networkpolicy-default-deny-all-ingress${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

# setup.sh never creates any NetworkPolicy, so plain existence is already a
# meaningful, non-trivially-true criterion on its own - but we still bundle
# the exact-shape assertions together so nothing here can be satisfied by a
# NetworkPolicy with the right name but the wrong (non-empty-podSelector /
# has-ingress-rules) shape. Each criterion below re-checks resource_exists
# itself (rather than delegating to a nested `bash -c`, where the sourced
# grading.sh functions are not visible) so a missing NetworkPolicy always
# fails every one of these, not just the first.
check_criterion "NetworkPolicy 'default-deny-ingress' exists in $QUESTION_ID with empty podSelector" \
  bash -c "kubectl get networkpolicy default-deny-ingress -n \"$QUESTION_ID\" >/dev/null 2>&1 && \
    [ \"\$(kubectl get networkpolicy default-deny-ingress -n \"$QUESTION_ID\" -o jsonpath='{.spec.podSelector}')\" = '{}' ]"

check_criterion "NetworkPolicy policyTypes is exactly ['Ingress']" \
  bash -c "kubectl get networkpolicy default-deny-ingress -n \"$QUESTION_ID\" >/dev/null 2>&1 && \
    [ \"\$(kubectl get networkpolicy default-deny-ingress -n \"$QUESTION_ID\" -o jsonpath='{.spec.policyTypes}')\" = '[\"Ingress\"]' ]"

check_criterion "NetworkPolicy defines no ingress rules (empty/absent ingress list)" \
  bash -c "kubectl get networkpolicy default-deny-ingress -n \"$QUESTION_ID\" >/dev/null 2>&1 && \
    [ -z \"\$(kubectl get networkpolicy default-deny-ingress -n \"$QUESTION_ID\" -o jsonpath='{.spec.ingress}')\" ]"

# setup.sh already leaves internal-svc's Deployment/Service healthy, so
# "untouched" alone would be trivially true before the candidate does
# anything (the pitfall this bank explicitly guards against). Bundle it with
# the NetworkPolicy's existence so this criterion only starts passing once
# the candidate has actually created default-deny-ingress.
check_criterion "Deployment/Service 'internal-svc' untouched AND NetworkPolicy 'default-deny-ingress' exists" \
  bash -c "kubectl get deployment internal-svc -n \"$QUESTION_ID\" >/dev/null 2>&1 && \
    kubectl get service internal-svc -n \"$QUESTION_ID\" >/dev/null 2>&1 && \
    kubectl get networkpolicy default-deny-ingress -n \"$QUESTION_ID\" >/dev/null 2>&1"

print_score
