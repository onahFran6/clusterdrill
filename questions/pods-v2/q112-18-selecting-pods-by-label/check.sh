#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e` on purpose - see lib/grading.sh header comment.
set -uo pipefail

QUESTION_ID="q112-18-selecting-pods-by-label${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Exactly web-1 and api-1 carry release=r42" \
  bash -c '
    got="$(kubectl get pods -n "'"$QUESTION_ID"'" -l release=r42 -o name 2>/dev/null | sed "s#pod/##" | sort | tr "\n" , )"
    [ "$got" = "api-1,web-1," ]
  '

check_criterion "web-1 carries annotation owner=team-iapetus" \
  bash -c '[ "$(kubectl get pod web-1 -n "'"$QUESTION_ID"'" -o jsonpath="{.metadata.annotations.owner}" 2>/dev/null)" = "team-iapetus" ]'

check_criterion "No Pod in this namespace still carries a temp label" \
  bash -c '[ -z "$(kubectl get pods -n "'"$QUESTION_ID"'" -l temp -o name 2>/dev/null)" ]'

print_score
