#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q109-46-pv-retain-recreate-from-released-data${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "PV 'archive-pv-new' exists with capacity 200Mi, ReadWriteOnce, Retain, hostPath /mnt/q109-46-archive" \
  bash -c "[ \"\$(kubectl get pv archive-pv-new -o jsonpath='{.spec.capacity.storage}' 2>/dev/null)\" = '200Mi' ] && \
    [ \"\$(kubectl get pv archive-pv-new -o jsonpath='{.spec.accessModes[0]}' 2>/dev/null)\" = 'ReadWriteOnce' ] && \
    [ \"\$(kubectl get pv archive-pv-new -o jsonpath='{.spec.persistentVolumeReclaimPolicy}' 2>/dev/null)\" = 'Retain' ] && \
    [ \"\$(kubectl get pv archive-pv-new -o jsonpath='{.spec.hostPath.path}' 2>/dev/null)\" = '/mnt/q109-46-archive' ]"

check_criterion "PVC 'archive-claim' is Bound to 'archive-pv-new'" \
  bash -c '
    for _ in $(seq 1 15); do
      vol="$(kubectl get pvc archive-claim -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.volumeName}" 2>/dev/null)"
      [ "$vol" = "archive-pv-new" ] && exit 0
      sleep 2
    done
    exit 1
  '

# Defined as a real function (not a nested `bash -c` string) so the
# multi-line manifest heredoc below doesn't have to survive an extra layer
# of shell-quoting - this function already has $QUESTION_ID and kubectl in
# scope directly.
verify_retained_data() {
  kubectl apply -n "$QUESTION_ID" -f - >/dev/null 2>&1 <<PODEOF
apiVersion: v1
kind: Pod
metadata:
  name: q109-46-verifier
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  restartPolicy: Never
  containers:
    - name: verifier
      image: busybox:1.36
      command: ["cat", "/data/archive.txt"]
      volumeMounts:
        - name: data
          mountPath: /data
  volumes:
    - name: data
      persistentVolumeClaim:
        claimName: archive-claim
PODEOF
  kubectl wait --for=jsonpath='{.status.phase}'=Succeeded pod/q109-46-verifier -n "$QUESTION_ID" --timeout=30s >/dev/null 2>&1
  local result
  result="$(kubectl logs q109-46-verifier -n "$QUESTION_ID" 2>/dev/null)"
  kubectl delete pod q109-46-verifier -n "$QUESTION_ID" --wait=false >/dev/null 2>&1
  [ "$result" = "ARCHIVED-DATA" ]
}

check_criterion "Retained data (archive.txt = ARCHIVED-DATA) is actually readable through the new claim" \
  verify_retained_data

print_score
