#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q106-19-role-restrict-secret-by-name${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Role 'db-credentials-reader' exists in $QUESTION_ID" \
  resource_exists role db-credentials-reader -n "$QUESTION_ID"

check_criterion "Role 'db-credentials-reader' restricts to resourceName 'db-credentials'" \
  bash -c "kubectl get role db-credentials-reader -n '$QUESTION_ID' \
    -o jsonpath='{.rules[*].resourceNames[*]}' | grep -qx db-credentials"

check_criterion "RoleBinding 'report-service-binding' exists in $QUESTION_ID" \
  resource_exists rolebinding report-service-binding -n "$QUESTION_ID"

check_criterion "RoleBinding grants 'db-credentials-reader' to 'report-service'" \
  bash -c "[ \"\$(kubectl get rolebinding report-service-binding -n '$QUESTION_ID' -o jsonpath='{.roleRef.name}' 2>/dev/null)\" = 'db-credentials-reader' ] && \
    [ \"\$(kubectl get rolebinding report-service-binding -n '$QUESTION_ID' -o jsonpath='{.subjects[0].name}' 2>/dev/null)\" = 'report-service' ]"

check_criterion "report-service CAN get Secret 'db-credentials'" \
  bash -c "kubectl auth can-i get secret/db-credentials \
    --as=system:serviceaccount:${QUESTION_ID}:report-service \
    -n ${QUESTION_ID} | grep -q '^yes'"

# "Cannot read payment-api-key" is true by default even with zero RBAC grants
# (the whole point of least-privilege), so it can't stand alone as a
# criterion - it would trivially pass in the unsolved state. Only count it
# once access to db-credentials is proven to actually exist, so this line
# is really testing "access is scoped to one Secret," not "no access at all."
check_criterion "report-service can read db-credentials but NOT payment-api-key (scoped, not blanket)" \
  bash -c "kubectl auth can-i get secret/db-credentials \
      --as=system:serviceaccount:${QUESTION_ID}:report-service -n ${QUESTION_ID} | grep -q '^yes' && \
    kubectl auth can-i get secret/payment-api-key \
      --as=system:serviceaccount:${QUESTION_ID}:report-service -n ${QUESTION_ID} | grep -q '^no'"

print_score
