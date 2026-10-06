#!/usr/bin/env bash
# Spec-only checks, same rationale as q108-14/q108-16/q108-26: this
# cluster's default CNI does not enforce NetworkPolicy, so only each
# object's fields are asserted, not live traffic blocking.
set -uo pipefail

QUESTION_ID="q113-15-default-deny-allow-one-path${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "NetworkPolicy 'default-deny' exists with empty podSelector, policyTypes [Ingress], no ingress rules" \
  bash -c "kubectl get networkpolicy default-deny -n '$QUESTION_ID' >/dev/null 2>&1 && \
    [ \"\$(kubectl get networkpolicy default-deny -n '$QUESTION_ID' -o jsonpath='{.spec.podSelector}')\" = '{}' ] && \
    [ \"\$(kubectl get networkpolicy default-deny -n '$QUESTION_ID' -o jsonpath='{.spec.policyTypes}')\" = '[\"Ingress\"]' ] && \
    [ -z \"\$(kubectl get networkpolicy default-deny -n '$QUESTION_ID' -o jsonpath='{.spec.ingress}')\" ]"

check_criterion "NetworkPolicy 'allow-frontend' selects backend, allows only frontend on TCP 80" \
  bash -c "kubectl get networkpolicy allow-frontend -n '$QUESTION_ID' >/dev/null 2>&1 && \
    [ \"\$(kubectl get networkpolicy allow-frontend -n '$QUESTION_ID' -o jsonpath='{.spec.podSelector.matchLabels.app}')\" = 'backend' ] && \
    [ \"\$(kubectl get networkpolicy allow-frontend -n '$QUESTION_ID' -o jsonpath='{.spec.policyTypes}')\" = '[\"Ingress\"]' ] && \
    [ \"\$(kubectl get networkpolicy allow-frontend -n '$QUESTION_ID' -o jsonpath='{.spec.ingress[0].from[0].podSelector.matchLabels.app}')\" = 'frontend' ] && \
    [ \"\$(kubectl get networkpolicy allow-frontend -n '$QUESTION_ID' -o jsonpath='{.spec.ingress[0].ports[0].protocol}:{.spec.ingress[0].ports[0].port}')\" = 'TCP:80' ]"

# setup.sh already leaves backend/backend-svc healthy, so "untouched" alone
# would be trivially true before the candidate does anything - bundle it
# with both policies' existence so this only starts passing once the
# candidate has actually created them.
check_criterion "backend/backend-svc untouched AND both NetworkPolicies exist" \
  bash -c "kubectl get deployment backend -n '$QUESTION_ID' >/dev/null 2>&1 && \
    kubectl get service backend-svc -n '$QUESTION_ID' >/dev/null 2>&1 && \
    kubectl get networkpolicy default-deny -n '$QUESTION_ID' >/dev/null 2>&1 && \
    kubectl get networkpolicy allow-frontend -n '$QUESTION_ID' >/dev/null 2>&1"

print_score
