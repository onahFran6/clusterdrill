#!/usr/bin/env bash
# No "set -e" - a failed criterion is a normal result, not a script error.
set -uo pipefail

QUESTION_ID="q107-22-multi-container-shared-log-volume${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

shipper_command="$(kget pod audit-logger '{.spec.containers[?(@.name=="shipper")].command}' -n "$QUESTION_ID")"

check_criterion "'shipper' container command tails audit.log" \
  bash -c "case '$shipper_command' in *audit.log*) exit 0;; *) exit 1;; esac"

# Give the container time to settle, then confirm 'shipper' was already
# Ready and its restartCount stays stable across a 15s window - proving it
# is not still crash-looping on the wrong filename.
restart_before="$(kget pod audit-logger '{.status.containerStatuses[?(@.name=="shipper")].restartCount}' -n "$QUESTION_ID")"
ready_before="$(kget pod audit-logger '{.status.containerStatuses[?(@.name=="shipper")].ready}' -n "$QUESTION_ID")"
writer_ready="$(kget pod audit-logger '{.status.containerStatuses[?(@.name=="writer")].ready}' -n "$QUESTION_ID")"
sleep 15
restart_after="$(kget pod audit-logger '{.status.containerStatuses[?(@.name=="shipper")].restartCount}' -n "$QUESTION_ID")"
ready_after="$(kget pod audit-logger '{.status.containerStatuses[?(@.name=="shipper")].ready}' -n "$QUESTION_ID")"

check_criterion "'shipper' container restartCount stayed stable across a 15s window" \
  [ "$restart_before" = "$restart_after" ]

check_criterion "'shipper' container was already Ready and stayed Ready (not crash-looping)" \
  bash -c "[ '$ready_before' = 'true' ] && [ '$ready_after' = 'true' ]"

check_criterion "Both 'writer' and 'shipper' containers are Ready" \
  bash -c "[ '$writer_ready' = 'true' ] && [ '$ready_after' = 'true' ]"

print_score
