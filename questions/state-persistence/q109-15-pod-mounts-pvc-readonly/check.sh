#!/usr/bin/env bash
# No "set -e" - a failed criterion is a normal result, not a script error.
set -uo pipefail

QUESTION_ID="q109-15-pod-mounts-pvc-readonly${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Pod 'reader-app' exists and has a volume backed by PVC readonly-claim" \
  bash -c '[ -n "$(kubectl get pod reader-app -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.volumes[?(@.persistentVolumeClaim.claimName==\"readonly-claim\")].name}" 2>/dev/null)" ]'

VOL_NAME="$(kget pod reader-app '{.spec.volumes[?(@.persistentVolumeClaim.claimName=="readonly-claim")].name}' -n "$QUESTION_ID")"

check_criterion "Container mounts that volume at /data" \
  [ "$(kget pod reader-app "{.spec.containers[0].volumeMounts[?(@.name==\"${VOL_NAME:-__none__}\")].mountPath}" -n "$QUESTION_ID")" = "/data" ]

check_criterion "Volume mount at /data is readOnly: true" \
  [ "$(kget pod reader-app "{.spec.containers[0].volumeMounts[?(@.name==\"${VOL_NAME:-__none__}\")].readOnly}" -n "$QUESTION_ID")" = "true" ]

check_criterion "Pod 'reader-app' is Running with the PVC mounted at /data" \
  bash -c '[ "$(kubectl get pod reader-app -n "'"$QUESTION_ID"'" -o jsonpath="{.status.phase}" 2>/dev/null)" = "Running" ] && kubectl exec reader-app -n "'"$QUESTION_ID"'" -- test -d /data >/dev/null 2>&1'

check_criterion "Writing to /data inside the container fails (read-only filesystem)" \
  bash -c 'kubectl exec reader-app -n "'"$QUESTION_ID"'" -- test -d /data >/dev/null 2>&1 && ! kubectl exec reader-app -n "'"$QUESTION_ID"'" -- sh -c "echo test > /data/f" >/dev/null 2>&1'

print_score
