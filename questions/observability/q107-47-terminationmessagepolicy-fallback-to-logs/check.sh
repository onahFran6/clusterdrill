#!/usr/bin/env bash
# No "set -e" - a failed criterion is a normal result, not a script error.
set -uo pipefail

QUESTION_ID="q107-47-terminationmessagepolicy-fallback-to-logs${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Container 'batch-runner' terminationMessagePolicy is FallbackToLogsOnError, command/image unchanged, and its last termination message actually contains the log line (fallback really worked, not just the field being set)" \
  bash -c '
    policy="$(kubectl get pod batch-runner -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.containers[0].terminationMessagePolicy}" 2>/dev/null)"
    [ "$policy" = "FallbackToLogsOnError" ] || exit 1
    image="$(kubectl get pod batch-runner -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.containers[0].image}" 2>/dev/null)"
    [ "$image" = "busybox:1.36" ] || exit 1
    for _ in $(seq 1 20); do
      msg="$(kubectl get pod batch-runner -n "'"$QUESTION_ID"'" -o jsonpath="{.status.containerStatuses[0].lastState.terminated.message}" 2>/dev/null)"
      case "$msg" in
        *"custom failure: disk quota exceeded"*) exit 0 ;;
      esac
      sleep 2
    done
    exit 1
  '

print_score
