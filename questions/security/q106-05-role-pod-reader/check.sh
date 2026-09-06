#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q106-05-role-pod-reader${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Role 'pod-reader' exists in $QUESTION_ID" \
  resource_exists role pod-reader -n "$QUESTION_ID"

check_criterion "Role 'pod-reader' targets resource 'pods'" \
  [ "$(kget role pod-reader '{.rules[0].resources[0]}' -n "$QUESTION_ID")" = "pods" ]

ROLE_VERBS="$(kget role pod-reader '{.rules[0].verbs}' -n "$QUESTION_ID")"

check_criterion "Role 'pod-reader' grants verb 'get'" \
  bash -c "[[ '$ROLE_VERBS' == *get* ]]"

check_criterion "Role 'pod-reader' grants verb 'list'" \
  bash -c "[[ '$ROLE_VERBS' == *list* ]]"

check_criterion "Role 'pod-reader' grants verb 'watch'" \
  bash -c "[[ '$ROLE_VERBS' == *watch* ]]"

print_score
