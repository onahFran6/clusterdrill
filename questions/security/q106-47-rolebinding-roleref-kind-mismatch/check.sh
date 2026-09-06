#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q106-47-rolebinding-roleref-kind-mismatch${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "RoleBinding 'auditor-binding' now references roleRef.kind Role (not ClusterRole)" \
  [ "$(kget rolebinding auditor-binding '{.roleRef.kind}' -n "$QUESTION_ID")" = "Role" ]

check_criterion "ServiceAccount 'auditor' can now get/list secrets in this namespace" \
  bash -c "
    kubectl auth can-i get secrets -n '$QUESTION_ID' --as='system:serviceaccount:$QUESTION_ID:auditor' | grep -qx yes || exit 1
    kubectl auth can-i list secrets -n '$QUESTION_ID' --as='system:serviceaccount:$QUESTION_ID:auditor' | grep -qx yes
  "

# Gated on the fix having landed too - the decoy ClusterRole grants
# configmaps get regardless of the candidate's fix, so checking this alone
# (via the OLD binding) would still read 'yes' before any fix, meaning a
# naive 'auditor cannot get configmaps' check could be trivially satisfied
# by NOT fixing anything if graded independently. Bundled with the correct
# roleRef here to make the point that the fix should narrow access, not
# widen it.
check_criterion "ServiceAccount 'auditor' no longer has the decoy ClusterRole's configmaps access via this binding" \
  bash -c "
    [ \"\$(kubectl get rolebinding auditor-binding -n '$QUESTION_ID' -o jsonpath='{.roleRef.kind}' 2>/dev/null)\" = 'Role' ] || exit 1
    kubectl auth can-i get configmaps -n '$QUESTION_ID' --as='system:serviceaccount:$QUESTION_ID:auditor' | grep -qx no
  "

print_score
