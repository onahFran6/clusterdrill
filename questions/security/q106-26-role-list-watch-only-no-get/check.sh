#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q106-26-role-list-watch-only-no-get${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Role 'pod-watcher' exists in $QUESTION_ID" \
  resource_exists role pod-watcher -n "$QUESTION_ID"

check_criterion "RoleBinding 'dashboard-binding' exists in $QUESTION_ID" \
  resource_exists rolebinding dashboard-binding -n "$QUESTION_ID"

check_criterion "RoleBinding grants 'pod-watcher' to 'dashboard-sa'" \
  bash -c "[ \"\$(kubectl get rolebinding dashboard-binding -n '$QUESTION_ID' -o jsonpath='{.roleRef.name}' 2>/dev/null)\" = 'pod-watcher' ] && \
    [ \"\$(kubectl get rolebinding dashboard-binding -n '$QUESTION_ID' -o jsonpath='{.subjects[0].name}' 2>/dev/null)\" = 'dashboard-sa' ]"

check_criterion "dashboard-sa CAN list pods" \
  bash -c "kubectl auth can-i list pods \
    --as=system:serviceaccount:${QUESTION_ID}:dashboard-sa \
    -n ${QUESTION_ID} | grep -q '^yes'"

check_criterion "dashboard-sa CAN watch pods" \
  bash -c "kubectl auth can-i watch pods \
    --as=system:serviceaccount:${QUESTION_ID}:dashboard-sa \
    -n ${QUESTION_ID} | grep -q '^yes'"

# "Cannot get pods" is true by default even with zero RBAC grants (the whole
# point of least-privilege), so it can't stand alone as a criterion - it
# would trivially pass in the unsolved state before the candidate does
# anything. Only count it once list+watch access is proven to actually
# exist, so this line is really testing "get was deliberately excluded,"
# not "no access at all."
check_criterion "dashboard-sa can list pods but NOT get pods (scoped, not blanket)" \
  bash -c "kubectl auth can-i list pods \
      --as=system:serviceaccount:${QUESTION_ID}:dashboard-sa -n ${QUESTION_ID} | grep -q '^yes' && \
    kubectl auth can-i get pods \
      --as=system:serviceaccount:${QUESTION_ID}:dashboard-sa -n ${QUESTION_ID} | grep -q '^no'"

print_score
