#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e` - a failed criterion is a
# normal result, not a script error (see lib/grading.sh header).
set -uo pipefail

QUESTION_ID="q107-23-terminationmessage-custom-path${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Pod 'batch-validator' terminationMessagePath is the default /dev/termination-log" \
  [ "$(kget pod batch-validator '{.spec.containers[0].terminationMessagePath}' -n "$QUESTION_ID")" = "/dev/termination-log" ]

check_criterion "Pod 'batch-validator' terminated container status contains the 'schema mismatch' message" \
  bash -c "kubectl get pod batch-validator -n '$QUESTION_ID' -o jsonpath='{.status.containerStatuses[0].state.terminated.message}' 2>/dev/null | grep -q 'schema mismatch'"

print_score
