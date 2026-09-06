#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q102-47-readonlyrootfs-sidecar-needs-scratch-volume${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

POD="hardened-lock-app"

# Pod is already 2/2 Running in the unsolved state (lock-manager swallows
# its own write error) - bundle the structural fix (readOnlyRootFilesystem
# preserved, /tmp now backed by a writable volume) with Running.
STRUCT_OK=0
for _ in $(seq 1 24); do
  RO_FS="$(kget pod "$POD" '{.spec.containers[?(@.name=="lock-manager")].securityContext.readOnlyRootFilesystem}' -n "$QUESTION_ID")"
  TMP_VOL="$(kget pod "$POD" '{.spec.containers[?(@.name=="lock-manager")].volumeMounts[?(@.mountPath=="/tmp")].name}' -n "$QUESTION_ID")"
  EMPTYDIR="$(kget pod "$POD" "{.spec.volumes[?(@.name==\"$TMP_VOL\")].emptyDir}" -n "$QUESTION_ID")"
  PHASE="$(kget pod "$POD" '{.status.phase}' -n "$QUESTION_ID")"
  READY_FLAGS="$(kget pod "$POD" '{.status.containerStatuses[*].ready}' -n "$QUESTION_ID")"
  READY_COUNT="$(echo "$READY_FLAGS" | tr ' ' '\n' | grep -c '^true$' 2>/dev/null || true)"
  APP_IMAGE="$(kget pod "$POD" '{.spec.containers[?(@.name=="app")].image}' -n "$QUESTION_ID")"
  LOCK_IMAGE="$(kget pod "$POD" '{.spec.containers[?(@.name=="lock-manager")].image}' -n "$QUESTION_ID")"

  if [ "$RO_FS" = "true" ] && [ -n "$TMP_VOL" ] && [ "$EMPTYDIR" = "{}" ] \
     && [ "$PHASE" = "Running" ] && [ "$READY_COUNT" = "2" ] \
     && [ "$APP_IMAGE" = "busybox:1.36" ] && [ "$LOCK_IMAGE" = "busybox:1.36" ]; then
    STRUCT_OK=1
    break
  fi
  sleep 4
done
check_criterion "'lock-manager' keeps readOnlyRootFilesystem: true, /tmp now backed by a writable emptyDir, Pod 2/2 Running" \
  [ "$STRUCT_OK" = "1" ]

CONTENT_OK=0
for _ in $(seq 1 12); do
  ACTUAL="$(kubectl exec "$POD" -c lock-manager -n "$QUESTION_ID" -- cat /tmp/lock.txt 2>/dev/null)"
  if [ "$ACTUAL" = "locked" ]; then
    CONTENT_OK=1
    break
  fi
  sleep 3
done
check_criterion "'lock-manager' container's /tmp/lock.txt contains exactly 'locked'" \
  [ "$CONTENT_OK" = "1" ]

print_score
