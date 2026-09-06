#!/usr/bin/env bash
# No "set -e" - a failed criterion is a normal result, not a script error.
set -uo pipefail

QUESTION_ID="q109-21-statefulset-volumeclaimtemplates${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

value_equals() {
  local actual="$1" expected="$2"
  [[ "$actual" == "$expected" ]]
}

check_criterion "StatefulSet db exists" \
  resource_exists statefulset db -n "$QUESTION_ID"

check_criterion "StatefulSet db has readyReplicas == 2" \
  value_equals "$(kget statefulset db '{.status.readyReplicas}' -n "$QUESTION_ID")" "2"

check_criterion "PVC data-db-0 exists" \
  resource_exists pvc data-db-0 -n "$QUESTION_ID"

check_criterion "PVC data-db-0 is Bound" \
  value_equals "$(kget pvc data-db-0 '{.status.phase}' -n "$QUESTION_ID")" "Bound"

check_criterion "PVC data-db-1 exists" \
  resource_exists pvc data-db-1 -n "$QUESTION_ID"

check_criterion "PVC data-db-1 is Bound" \
  value_equals "$(kget pvc data-db-1 '{.status.phase}' -n "$QUESTION_ID")" "Bound"

print_score
