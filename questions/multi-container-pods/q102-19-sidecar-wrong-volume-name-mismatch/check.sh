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

# Poll for a stable Running/2-ready snapshot rather than a single read, since
# a just-fixed pod takes a moment past apply to actually reach Running, and
# an old crash-looping pod can also flap through transient states.
POD_HEALTHY=0
for _ in $(seq 1 24); do
  PHASE="$(kget pod metrics-pair '{.status.phase}' -n "$QUESTION_ID")"
  READY_FLAGS="$(kget pod metrics-pair '{.status.containerStatuses[*].ready}' -n "$QUESTION_ID")"
  READY_COUNT="$(echo "$READY_FLAGS" | tr ' ' '\n' | grep -c '^true$' 2>/dev/null || true)"
  if [ "$PHASE" = "Running" ] && [ "$READY_COUNT" = "2" ]; then
    POD_HEALTHY=1
    break
  fi
  sleep 5
done
check_criterion "Pod 'metrics-pair' is Running with 2/2 containers ready" \
  [ "$POD_HEALTHY" = "1" ]

print_score
