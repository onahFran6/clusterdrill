#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q109-35-pod-mounts-pvc-and-emptydir-together${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Pod 'report-builder' exists and is Running" \
  bash -c "[ \"\$(kubectl get pod report-builder -n '$QUESTION_ID' -o jsonpath='{.status.phase}' 2>/dev/null)\" = 'Running' ]"

check_criterion "PVC 'data-claim' mounted at /data" \
  bash -c '
    vol="$(kubectl get pod report-builder -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.volumes[?(@.persistentVolumeClaim.claimName==\"data-claim\")].name}" 2>/dev/null)"
    [ -n "$vol" ] || exit 1
    mount_path="$(kubectl get pod report-builder -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.containers[0].volumeMounts[?(@.name==\"$vol\")].mountPath}" 2>/dev/null)"
    [ "$mount_path" = "/data" ]
  '

check_criterion "emptyDir 'scratch' mounted at /scratch" \
  bash -c '
    is_emptydir="$(kubectl get pod report-builder -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.volumes[?(@.name==\"scratch\")].emptyDir}" 2>/dev/null)"
    [ -n "$is_emptydir" ] || exit 1
    mount_path="$(kubectl get pod report-builder -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.containers[0].volumeMounts[?(@.name==\"scratch\")].mountPath}" 2>/dev/null)"
    [ "$mount_path" = "/scratch" ]
  '

print_score
