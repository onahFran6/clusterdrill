#!/usr/bin/env bash
# Grades ONLY live cluster state (spec-level - does not require Running,
# since a still-broken pod may crash-loop rather than reach Running).
# No `set -e`.
set -uo pipefail

QUESTION_ID="q102-12-broken-multicontainer-pod-fix${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

# Fetch the volume list and each container's referenced volumeMounts names
# OUTSIDE any subshell (kget must never run inside bash -c). Both cache-vol
# and empty-vol always exist in spec.volumes (setup.sh defines both), so
# "the referenced name exists somewhere in volumes" is true even in the
# unsolved state and must NOT be its own criterion (would be a false
# positive per the no-false-positives rule). The only real bug to fix is
# THAT the two containers reference the SAME shared volume at /cache.
VOLUME_NAMES="$(kget pod broken-app '{.spec.volumes[*].name}' -n "$QUESTION_ID")"

WRITER_CACHE_MOUNT_NAME="$(kget pod broken-app '{.spec.containers[?(@.name=="writer")].volumeMounts[?(@.mountPath=="/cache")].name}' -n "$QUESTION_ID")"
READER_CACHE_MOUNT_NAME="$(kget pod broken-app '{.spec.containers[?(@.name=="reader")].volumeMounts[?(@.mountPath=="/cache")].name}' -n "$QUESTION_ID")"

if [ -n "$WRITER_CACHE_MOUNT_NAME" ] && [ "$WRITER_CACHE_MOUNT_NAME" = "$READER_CACHE_MOUNT_NAME" ]; then
  SHARED_OK=1
else
  SHARED_OK=0
fi
check_criterion "writer and reader mount the SAME volume at /cache (shared, not the empty-vol decoy)" \
  [ "$SHARED_OK" = "1" ]

# Container identity must be preserved by the fix (candidate should only
# correct the volume reference, not rebuild the pod with different
# containers). Combined with the shared-mount fix above into one gate so
# this doesn't score as an always-true criterion against the unsolved
# state, per the "no false positives" rule - it only ever adds a point once
# the real bug is also fixed.
CONTAINER_NAMES="$(kget pod broken-app '{.spec.containers[*].name}' -n "$QUESTION_ID")"
if [ "$SHARED_OK" = "1" ] && [ "$CONTAINER_NAMES" = "writer reader" ]; then
  IDENTITY_PRESERVED=1
else
  IDENTITY_PRESERVED=0
fi
check_criterion "container count/names (writer, reader) unchanged by the fix" \
  [ "$IDENTITY_PRESERVED" = "1" ]

print_score
