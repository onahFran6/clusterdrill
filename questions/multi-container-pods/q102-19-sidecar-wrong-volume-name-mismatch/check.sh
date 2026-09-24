#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q102-19-sidecar-wrong-volume-name-mismatch${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

# Both "shared-data" and "shared-dat" always exist somewhere in spec.volumes
# (setup.sh defines both), so "a volume named shared-data exists in the pod"
# is true even in the unsolved state and must NOT be its own criterion (would
# be a false positive per the no-false-positives rule). The only real bug to
# fix is THAT the sidecar container's volumeMounts entry actually references
# "shared-data" (not the "shared-dat" decoy) - bundled with the container
# names/count so a rebuilt-from-scratch pod can't fake it either.
WRITER_MOUNT_NAME="$(kget pod metrics-pair '{.spec.containers[?(@.name=="writer")].volumeMounts[?(@.mountPath=="/var/writer")].name}' -n "$QUESTION_ID")"
SIDECAR_MOUNT_NAME="$(kget pod metrics-pair '{.spec.containers[?(@.name=="sidecar")].volumeMounts[?(@.mountPath=="/var/sidecar")].name}' -n "$QUESTION_ID")"
CONTAINER_NAMES="$(kget pod metrics-pair '{.spec.containers[*].name}' -n "$QUESTION_ID")"

if [ "$WRITER_MOUNT_NAME" = "shared-data" ] && [ "$SIDECAR_MOUNT_NAME" = "shared-data" ] && [ "$CONTAINER_NAMES" = "writer sidecar" ]; then
  MOUNTS_FIXED=1
else
  MOUNTS_FIXED=0
fi
check_criterion "both 'writer' and 'sidecar' volumeMounts reference the shared 'shared-data' volume (not the 'shared-dat' decoy), container identity unchanged" \
  [ "$MOUNTS_FIXED" = "1" ]

# Running/2-ready alone is NOT sufficient proof the volumes are actually
# connected: busybox's `tail -f /var/sidecar/metrics.log` doesn't crash or
# exit just because its target never appears on a disconnected decoy volume
# - it just idles silently, so a still-broken mount can stay Running/Ready
# forever (a real false positive this check.sh used to have). The real
# proof is content: 'writer' keeps appending to metrics.log on the SHARED
# volume every 5s, so if 'sidecar' is mounted to the correct volume, that
# content shows up on its side too. Poll since 'writer' needs a moment to
# write its first line after the pod (re)starts.
CONTENT_OK=0
for _ in $(seq 1 24); do
  PHASE="$(kget pod metrics-pair '{.status.phase}' -n "$QUESTION_ID")"
  READY_FLAGS="$(kget pod metrics-pair '{.status.containerStatuses[*].ready}' -n "$QUESTION_ID")"
  READY_COUNT="$(echo "$READY_FLAGS" | tr ' ' '\n' | grep -c '^true$' 2>/dev/null || true)"
  SIDECAR_CONTENT="$(kubectl exec metrics-pair -c sidecar -n "$QUESTION_ID" -- cat /var/sidecar/metrics.log 2>/dev/null)"
  if [ "$PHASE" = "Running" ] && [ "$READY_COUNT" = "2" ] && echo "$SIDECAR_CONTENT" | grep -q "metric"; then
    CONTENT_OK=1
    break
  fi
  sleep 5
done
check_criterion "Pod 'metrics-pair' is Running 2/2 ready and 'sidecar' actually sees 'writer's live metrics.log content through the shared volume (not a disconnected decoy)" \
  [ "$CONTENT_OK" = "1" ]

print_score
