#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q102-50-livenessprobe-wrong-path-crashloop${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

POD="false-alarm-app"

# Structural fix: probe command corrected to the real path. Checked once up
# front and gated into the SAME criterion as the stability proof below - a
# CrashLoopBackOff's retry delay grows (10s, 20s, 40s...), so a short
# polling window can land in a quiet gap between restarts even while still
# broken. Gating on the structural fix first means an unsolved Pod can
# never score here just by getting lucky with backoff timing.
PROBE_CMD="$(kget pod "$POD" '{.spec.containers[?(@.name=="app")].livenessProbe.exec.command}' -n "$QUESTION_ID")"
APP_IMAGE="$(kget pod "$POD" '{.spec.containers[?(@.name=="app")].image}' -n "$QUESTION_ID")"
SIDECAR_IMAGE="$(kget pod "$POD" '{.spec.containers[?(@.name=="sidecar")].image}' -n "$QUESTION_ID")"
STRUCT_OK=0
if echo "$PROBE_CMD" | grep -q '/tmp/healthy' \
   && [ "$APP_IMAGE" = "busybox:1.36" ] && [ "$SIDECAR_IMAGE" = "busybox:1.36" ]; then
  STRUCT_OK=1
fi

# The real proof: give the probe several full cycles (periodSeconds=3) to
# prove it settled - restartCount must stay flat across repeated polls,
# not just be low at one instant.
STABLE_OK=0
PREV_COUNT=""
STABLE_STREAK=0
for _ in $(seq 1 12); do
  PHASE="$(kget pod "$POD" '{.status.phase}' -n "$QUESTION_ID")"
  READY_FLAGS="$(kget pod "$POD" '{.status.containerStatuses[*].ready}' -n "$QUESTION_ID")"
  READY_COUNT="$(echo "$READY_FLAGS" | tr ' ' '\n' | grep -c '^true$' 2>/dev/null || true)"
  COUNT="$(kget pod "$POD" '{.status.containerStatuses[?(@.name=="app")].restartCount}' -n "$QUESTION_ID")"

  if [ "$PHASE" = "Running" ] && [ "$READY_COUNT" = "2" ] && [ -n "$COUNT" ] && [ "$COUNT" = "$PREV_COUNT" ]; then
    STABLE_STREAK=$((STABLE_STREAK + 1))
  else
    STABLE_STREAK=0
  fi
  PREV_COUNT="$COUNT"
  if [ "$STABLE_STREAK" -ge 4 ]; then
    STABLE_OK=1
    break
  fi
  sleep 4
done

check_criterion "'app' livenessProbe execs the real path /tmp/healthy (not /tmp/health), containers/images unchanged, Pod 2/2 Running with a stable (non-incrementing) restart count" \
  bash -c "[ '$STRUCT_OK' = '1' ] && [ '$STABLE_OK' = '1' ]"

print_score
