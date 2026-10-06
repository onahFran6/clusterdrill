#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e` on purpose - see lib/grading.sh header comment.
set -uo pipefail

QUESTION_ID="q112-06-persistent-data-survives-pod-deletion${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "PV q112-06-static-pv exists with the exact required spec" \
  bash -c '
    cap="$(kubectl get pv q112-06-static-pv -o jsonpath="{.spec.capacity.storage}" 2>/dev/null)"
    mode="$(kubectl get pv q112-06-static-pv -o jsonpath="{.spec.accessModes[0]}" 2>/dev/null)"
    sc="$(kubectl get pv q112-06-static-pv -o jsonpath="{.spec.storageClassName}" 2>/dev/null)"
    path="$(kubectl get pv q112-06-static-pv -o jsonpath="{.spec.hostPath.path}" 2>/dev/null)"
    label="$(kubectl get pv q112-06-static-pv -o jsonpath="{.metadata.labels.clusterdrill-question}" 2>/dev/null)"
    [ "$cap" = "1Gi" ] && [ "$mode" = "ReadWriteOnce" ] && [ "$sc" = "manual-q112-06" ] \
      && [ "$path" = "/mnt/q112-06-data" ] && [ "$label" = "'"$QUESTION_ID"'" ]
  '

check_criterion "PVC triton-pvc is Bound to the PV, reporting the PV's 1Gi capacity" \
  bash -c '
    phase="$(kubectl get pvc triton-pvc -n "'"$QUESTION_ID"'" -o jsonpath="{.status.phase}" 2>/dev/null)"
    cap="$(kubectl get pvc triton-pvc -n "'"$QUESTION_ID"'" -o jsonpath="{.status.capacity.storage}" 2>/dev/null)"
    sc="$(kubectl get pvc triton-pvc -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.storageClassName}" 2>/dev/null)"
    [ "$phase" = "Bound" ] && [ "$cap" = "1Gi" ] && [ "$sc" = "manual-q112-06" ]
  '

check_criterion "Original Pod 'writer' is gone and 'reader' is Running in its place" \
  bash -c '
    ! kubectl get pod writer -n "'"$QUESTION_ID"'" >/dev/null 2>&1 \
      && [ "$(kubectl get pod reader -n "'"$QUESTION_ID"'" -o jsonpath="{.status.phase}" 2>/dev/null)" = "Running" ]
  '

check_criterion "reader's logs contain the data writer saved" \
  bash -c 'kubectl logs reader -n "'"$QUESTION_ID"'" 2>/dev/null | grep -q saved-by-writer'

print_score
