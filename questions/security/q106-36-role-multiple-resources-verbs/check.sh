#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q106-36-role-multiple-resources-verbs${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

SA="system:serviceaccount:$QUESTION_ID:log-viewer"

check_criterion "ServiceAccount 'log-viewer' can get/list/watch pods" \
  bash -c "
    kubectl auth can-i get pods -n '$QUESTION_ID' --as='$SA' | grep -qx yes || exit 1
    kubectl auth can-i list pods -n '$QUESTION_ID' --as='$SA' | grep -qx yes || exit 1
    kubectl auth can-i watch pods -n '$QUESTION_ID' --as='$SA' | grep -qx yes
  "

check_criterion "ServiceAccount 'log-viewer' can get pods/log" \
  bash -c "kubectl auth can-i get pods/log -n '$QUESTION_ID' --as='$SA' | grep -qx yes"

# Gated on the read grants too - "cannot delete" is trivially true before
# any Role exists at all (RBAC denies by default), so on its own this would
# never score 0 pre-solve.
check_criterion "ServiceAccount 'log-viewer' cannot delete pods (read-only, not over-granted)" \
  bash -c "
    kubectl auth can-i get pods -n '$QUESTION_ID' --as='$SA' | grep -qx yes || exit 1
    kubectl auth can-i delete pods -n '$QUESTION_ID' --as='$SA' | grep -qx no
  "

print_score
