#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q106-28-chained-rbac-role-wrong-apigroup${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

SA="system:serviceaccount:${QUESTION_ID}:ci-bot"

# The Role/RoleBinding/ServiceAccount names, and the RoleBinding's roleRef
# and subject, are ALL already correct straight out of setup.sh - only the
# Role's apiGroups entry for 'deployments' is broken. So none of those
# already-true facts can stand alone as a criterion; every criterion below
# also re-checks the one thing that actually changes (the apiGroups value
# and the resulting live can-i outcome), so nothing scores until the
# candidate fixes the Role.

check_criterion "Role 'deploy-reader' rule for 'deployments' uses apiGroups 'apps' (not core)" \
  bash -c "kubectl get role deploy-reader -n '$QUESTION_ID' \
    -o jsonpath='{range .rules[?(@.resources[0]==\"deployments\")]}{.apiGroups[*]}{\"\n\"}{end}' 2>/dev/null | \
    grep -qx apps"

# The RoleBinding's roleRef/subject names are already correct straight out
# of setup.sh (only the Role's apiGroups is broken), so "RoleBinding still
# correct" can't stand alone as a criterion - it would trivially pass in the
# unsolved state. Bundle it with the apiGroups fix so nothing scores here
# until the candidate has actually fixed the Role AND left the binding
# untouched (per the task's "do not recreate the RoleBinding" constraint).
check_criterion "RoleBinding 'ci-bot-binding' untouched (still binds fixed 'deploy-reader' to 'ci-bot')" \
  bash -c "[ \"\$(kubectl get rolebinding ci-bot-binding -n '$QUESTION_ID' -o jsonpath='{.roleRef.name}' 2>/dev/null)\" = 'deploy-reader' ] && \
    [ \"\$(kubectl get rolebinding ci-bot-binding -n '$QUESTION_ID' -o jsonpath='{.subjects[0].name}' 2>/dev/null)\" = 'ci-bot' ] && \
    kubectl get role deploy-reader -n '$QUESTION_ID' \
      -o jsonpath='{range .rules[?(@.resources[0]==\"deployments\")]}{.apiGroups[*]}{\"\n\"}{end}' 2>/dev/null | \
      grep -qx apps"

check_criterion "ci-bot CAN get deployments after the fix" \
  bash -c "kubectl auth can-i get deployments --as='$SA' -n '$QUESTION_ID' | grep -q '^yes'"

check_criterion "ci-bot CAN list deployments after the fix" \
  bash -c "kubectl auth can-i list deployments --as='$SA' -n '$QUESTION_ID' | grep -q '^yes'"

# 'delete' being denied is true by default with zero RBAC grants, so it
# can't stand alone as a criterion either - it would trivially pass in the
# unsolved state. Only count it once get+list access is proven to actually
# exist, so this line really tests "the fix didn't over-grant," not "no
# access at all."
check_criterion "ci-bot can get/list deployments but is still denied delete (fix did not over-grant)" \
  bash -c "kubectl auth can-i get deployments --as='$SA' -n '$QUESTION_ID' | grep -q '^yes' && \
    kubectl auth can-i list deployments --as='$SA' -n '$QUESTION_ID' | grep -q '^yes' && \
    kubectl auth can-i delete deployments --as='$SA' -n '$QUESTION_ID' | grep -q '^no'"

print_score
