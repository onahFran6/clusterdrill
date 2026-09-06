#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q106-11-pod-runasuser-runasgroup${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Pod 'worker' exists in $QUESTION_ID" \
  resource_exists pod worker -n "$QUESTION_ID"

check_criterion "Pod 'worker' runs image 'busybox:1.36'" \
  [ "$(kget pod worker '{.spec.containers[0].image}' -n "$QUESTION_ID")" = "busybox:1.36" ]

check_criterion "Pod 'worker' securityContext.runAsUser is 1000" \
  [ "$(kget pod worker '{.spec.securityContext.runAsUser}' -n "$QUESTION_ID")" = "1000" ]

check_criterion "Pod 'worker' securityContext.runAsGroup is 3000" \
  [ "$(kget pod worker '{.spec.securityContext.runAsGroup}' -n "$QUESTION_ID")" = "3000" ]

print_score
