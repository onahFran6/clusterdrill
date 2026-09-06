#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e` - a failed criterion is a
# normal result, not a script error (see lib/grading.sh header).
set -uo pipefail

QUESTION_ID="q107-21-prestop-graceful-shutdown-log${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

# kubectl's jsonpath printer JSON-encodes the raw field value, which HTML-
# escapes ">" as the literal 6-character sequence > - compare using
# the JSON-decoded form via `kubectl ... -o json | jq` instead of raw
# jsonpath so this matches the human-readable command candidates author.
PRESTOP_CMD="$(kubectl get pod session-worker -n "$QUESTION_ID" \
  -o json 2>/dev/null | jq -c '.spec.containers[0].lifecycle.preStop.exec.command // empty')"

check_criterion "Pod 'session-worker' has the expected preStop exec command" \
  [ "$PRESTOP_CMD" = '["sh","-c","echo shutting down > /tmp/shutdown.log; sleep 2"]' ]

check_criterion "terminationGracePeriodSeconds is 10" \
  [ "$(kget pod session-worker '{.spec.terminationGracePeriodSeconds}' -n "$QUESTION_ID")" = "10" ]

check_criterion "Pod 'session-worker' is Running and Ready" \
  [ "$(kget pod session-worker '{.status.phase}' -n "$QUESTION_ID")" = "Running" -a \
    "$(kget pod session-worker '{.status.conditions[?(@.type=="Ready")].status}' -n "$QUESTION_ID")" = "True" -a \
    "$PRESTOP_CMD" = '["sh","-c","echo shutting down > /tmp/shutdown.log; sleep 2"]' ]

print_score
