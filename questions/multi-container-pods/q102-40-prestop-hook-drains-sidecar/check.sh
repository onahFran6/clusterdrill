#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q102-40-prestop-hook-drains-sidecar${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

POD="batching-shipper"

# The bug only manifests during Pod shutdown, not in steady-state output -
# Pod is already 2/2 Running in the unsolved state either way. Grade the
# STRUCTURAL fix (preStop hook + long enough grace period) together with
# confirming the Pod is still healthy, so nothing scores on an untouched
# manifest.
STRUCT_OK=0
for _ in $(seq 1 24); do
  PRESTOP_CMD="$(kget pod "$POD" '{.spec.containers[?(@.name=="log-shipper")].lifecycle.preStop.exec.command}' -n "$QUESTION_ID")"
  GRACE_PERIOD="$(kget pod "$POD" '{.spec.terminationGracePeriodSeconds}' -n "$QUESTION_ID")"
  PHASE="$(kget pod "$POD" '{.status.phase}' -n "$QUESTION_ID")"
  READY_FLAGS="$(kget pod "$POD" '{.status.containerStatuses[*].ready}' -n "$QUESTION_ID")"
  READY_COUNT="$(echo "$READY_FLAGS" | tr ' ' '\n' | grep -c '^true$' 2>/dev/null || true)"
  APP_IMAGE="$(kget pod "$POD" '{.spec.containers[?(@.name=="app")].image}' -n "$QUESTION_ID")"
  SHIPPER_IMAGE="$(kget pod "$POD" '{.spec.containers[?(@.name=="log-shipper")].image}' -n "$QUESTION_ID")"

  if echo "$PRESTOP_CMD" | grep -q 'buffer.log' && echo "$PRESTOP_CMD" | grep -q 'shipped.log' \
     && [ -n "$GRACE_PERIOD" ] && [ "$GRACE_PERIOD" -ge 15 ] 2>/dev/null \
     && [ "$PHASE" = "Running" ] && [ "$READY_COUNT" = "2" ] \
     && [ "$APP_IMAGE" = "busybox:1.36" ] && [ "$SHIPPER_IMAGE" = "busybox:1.36" ]; then
    STRUCT_OK=1
    break
  fi
  sleep 4
done
check_criterion "'log-shipper' has a preStop hook flushing buffer.log into shipped.log, terminationGracePeriodSeconds >= 15, Pod 2/2 Running" \
  [ "$STRUCT_OK" = "1" ]

print_score
