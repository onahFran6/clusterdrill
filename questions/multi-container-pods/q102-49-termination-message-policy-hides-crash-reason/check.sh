#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q102-49-termination-message-policy-hides-crash-reason${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

POD="crashy-worker"

# "worker" crash-loops in BOTH the unsolved and solved state (the fix makes
# the crash diagnosable, it doesn't stop it) - poll until it has actually
# restarted at least once, then check the real proof: lastState.terminated
# .message actually captured the diagnostic, which only happens with the
# structural fix (terminationMessagePolicy) in place.
STRUCT_OK=0
for _ in $(seq 1 30); do
  POLICY="$(kget pod "$POD" '{.spec.containers[?(@.name=="worker")].terminationMessagePolicy}' -n "$QUESTION_ID")"
  RESTART_COUNT="$(kget pod "$POD" '{.status.containerStatuses[?(@.name=="worker")].restartCount}' -n "$QUESTION_ID")"
  MESSAGE="$(kget pod "$POD" '{.status.containerStatuses[?(@.name=="worker")].lastState.terminated.message}' -n "$QUESTION_ID")"
  WORKER_IMAGE="$(kget pod "$POD" '{.spec.containers[?(@.name=="worker")].image}' -n "$QUESTION_ID")"
  SIDECAR_IMAGE="$(kget pod "$POD" '{.spec.containers[?(@.name=="sidecar")].image}' -n "$QUESTION_ID")"

  if [ "$POLICY" = "FallbackToLogsOnError" ] \
     && [ -n "$RESTART_COUNT" ] && [ "$RESTART_COUNT" -ge 1 ] 2>/dev/null \
     && echo "$MESSAGE" | grep -q 'FATAL: config file missing at /etc/app/config.yaml' \
     && [ "$WORKER_IMAGE" = "busybox:1.36" ] && [ "$SIDECAR_IMAGE" = "busybox:1.36" ]; then
    STRUCT_OK=1
    break
  fi
  sleep 5
done
check_criterion "'worker' has terminationMessagePolicy: FallbackToLogsOnError, and after restarting its lastState.terminated.message captures the real crash diagnostic" \
  [ "$STRUCT_OK" = "1" ]

print_score
