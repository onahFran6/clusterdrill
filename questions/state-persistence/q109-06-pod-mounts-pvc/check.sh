#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q109-06-pod-mounts-pvc${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Pod 'notes-app' exists in $QUESTION_ID" \
  resource_exists pod notes-app -n "$QUESTION_ID"

check_criterion "Volume 'notes-storage' references PVC notes-pvc" \
  [ "$(kget pod notes-app '{.spec.volumes[?(@.name=="notes-storage")].persistentVolumeClaim.claimName}' -n "$QUESTION_ID")" = "notes-pvc" ]

check_criterion "Container 'notes' mounts 'notes-storage' at /data/notes" \
  [ "$(kget pod notes-app '{.spec.containers[0].volumeMounts[?(@.name=="notes-storage")].mountPath}' -n "$QUESTION_ID")" = "/data/notes" ]

check_criterion "Pod 'notes-app' is Running" \
  [ "$(kget pod notes-app '{.status.phase}' -n "$QUESTION_ID")" = "Running" ]

print_score
