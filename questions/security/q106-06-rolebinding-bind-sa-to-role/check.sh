#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q106-06-rolebinding-bind-sa-to-role${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "RoleBinding 'config-watcher-binding' exists in $QUESTION_ID" \
  resource_exists rolebinding config-watcher-binding -n "$QUESTION_ID"

check_criterion "RoleBinding references Role 'configmap-reader'" \
  [ "$(kget rolebinding config-watcher-binding '{.roleRef.name}' -n "$QUESTION_ID")" = "configmap-reader" ]

check_criterion "RoleBinding roleRef kind is 'Role'" \
  [ "$(kget rolebinding config-watcher-binding '{.roleRef.kind}' -n "$QUESTION_ID")" = "Role" ]

check_criterion "RoleBinding subject is ServiceAccount 'config-watcher'" \
  [ "$(kget rolebinding config-watcher-binding '{.subjects[0].name}' -n "$QUESTION_ID")" = "config-watcher" ]

check_criterion "RoleBinding subject kind is 'ServiceAccount'" \
  [ "$(kget rolebinding config-watcher-binding '{.subjects[0].kind}' -n "$QUESTION_ID")" = "ServiceAccount" ]

check_criterion "kubectl auth can-i confirms config-watcher can get configmaps" \
  bash -c "kubectl auth can-i get configmaps \
    --as=system:serviceaccount:${QUESTION_ID}:config-watcher \
    -n ${QUESTION_ID} | grep -q '^yes'"

print_score
