#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q114-05-get-data-back-after-delete${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolume
metadata:
  name: q114-05-pv
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  capacity:
    storage: 1Gi
  accessModes: ["ReadWriteOnce"]
  persistentVolumeReclaimPolicy: Retain
  storageClassName: manual-q114-05
  hostPath:
    path: /mnt/q114-05-pv
    type: DirectoryOrCreate
EOF

# Only seed the writer/PVC dance if the PV isn't already Released (i.e. this
# is a fresh PV that hasn't been written to yet) - keeps setup.sh idempotent
# across repeated standalone runs.
phase="$(kubectl get pv q114-05-pv -o jsonpath='{.status.phase}' 2>/dev/null)"
if [[ "$phase" != "Released" ]]; then
  kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: rhine-old
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  storageClassName: manual-q114-05
  accessModes: ["ReadWriteOnce"]
  volumeName: q114-05-pv
  resources:
    requests:
      storage: 1Gi
---
apiVersion: v1
kind: Pod
metadata:
  name: writer
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  volumes:
    - name: data
      persistentVolumeClaim:
        claimName: rhine-old
  containers:
    - name: writer
      image: busybox:1.36
      command: ["sh", "-c", "echo precious data > /data/msg; sleep 3600"]
      volumeMounts:
        - name: data
          mountPath: /data
EOF

  kubectl wait --for=condition=Ready pod/writer -n "$QUESTION_ID" --timeout=60s
  kubectl delete pod writer -n "$QUESTION_ID" --force --grace-period=0 --ignore-not-found
  kubectl delete pvc rhine-old -n "$QUESTION_ID" --ignore-not-found --wait=true
fi

echo "setup.sh: $QUESTION_ID ready"
