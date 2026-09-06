#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q106-15-capabilities-add-drop${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Pod 'net-tool' exists in $QUESTION_ID" \
  resource_exists pod net-tool -n "$QUESTION_ID"

DROP_LIST="$(kget pod net-tool '{.spec.containers[0].securityContext.capabilities.drop}' -n "$QUESTION_ID")"
ADD_LIST="$(kget pod net-tool '{.spec.containers[0].securityContext.capabilities.add}' -n "$QUESTION_ID")"

check_criterion "Container 'net-tool' drops capability 'ALL'" \
  bash -c "[[ '$DROP_LIST' == *ALL* ]]"

check_criterion "Container 'net-tool' adds back only 'NET_BIND_SERVICE'" \
  [ "$ADD_LIST" = "[\"NET_BIND_SERVICE\"]" ]

print_score
