#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q102-37-sidecar-downward-api-podname-missing${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

POD="tagged-shipper"

# Pod is already 2/2 Running in the unsolved state (shipper doesn't crash,
# it just tags with the wrong name) - bundle the structural fix with
# Running into ONE criterion so nothing scores until the real fix lands.
STRUCT_OK=0
for _ in $(seq 1 24); do
  FIELD_PATH="$(kget pod "$POD" '{.spec.containers[?(@.name=="shipper")].env[?(@.name=="POD_NAME")].valueFrom.fieldRef.fieldPath}' -n "$QUESTION_ID")"
  PHASE="$(kget pod "$POD" '{.status.phase}' -n "$QUESTION_ID")"
  READY_FLAGS="$(kget pod "$POD" '{.status.containerStatuses[*].ready}' -n "$QUESTION_ID")"
  READY_COUNT="$(echo "$READY_FLAGS" | tr ' ' '\n' | grep -c '^true$' 2>/dev/null || true)"
  APP_IMAGE="$(kget pod "$POD" '{.spec.containers[?(@.name=="app")].image}' -n "$QUESTION_ID")"
  SHIPPER_IMAGE="$(kget pod "$POD" '{.spec.containers[?(@.name=="shipper")].image}' -n "$QUESTION_ID")"

  if [ "$FIELD_PATH" = "metadata.name" ] && [ "$PHASE" = "Running" ] && [ "$READY_COUNT" = "2" ] \
     && [ "$APP_IMAGE" = "busybox:1.36" ] && [ "$SHIPPER_IMAGE" = "busybox:1.36" ]; then
    STRUCT_OK=1
    break
  fi
  sleep 5
done
check_criterion "'shipper' has POD_NAME via Downward API fieldRef metadata.name, Pod 2/2 Running, containers/images unchanged" \
  [ "$STRUCT_OK" = "1" ]

CONTENT_OK=0
for _ in $(seq 1 12); do
  ACTUAL="$(kubectl exec "$POD" -c shipper -n "$QUESTION_ID" -- cat /logs/shipped.log 2>/dev/null)"
  if [ "$ACTUAL" = "[tagged-shipper] tagged-shipper: request handled" ]; then
    CONTENT_OK=1
    break
  fi
  sleep 5
done
check_criterion "'shipper' container's /logs/shipped.log is tagged with the real Pod name, not 'unknown-pod'" \
  [ "$CONTENT_OK" = "1" ]

print_score
