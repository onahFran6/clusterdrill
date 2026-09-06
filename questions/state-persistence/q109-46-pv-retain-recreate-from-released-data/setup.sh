#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q109-46-pv-retain-recreate-from-released-data${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: archive-pv-old
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  capacity:
    storage: 200Mi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: ""
  hostPath:
    path: /mnt/q109-46-archive
EOF

kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: archive-claim
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: ""
  resources:
    requests:
      storage: 200Mi
EOF

kubectl wait --for=jsonpath='{.status.phase}'=Bound pvc/archive-claim -n "$QUESTION_ID" --timeout=60s

# Write a marker file into the retained data before tearing everything down,
# so check.sh can later prove the *data* actually survived, not just that a
# same-named PV object exists again.
kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: seed-helper
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  restartPolicy: Never
  containers:
    - name: seed-helper
      image: busybox:1.36
      command: ["sh", "-c", "echo ARCHIVED-DATA > /data/archive.txt"]
      volumeMounts:
        - name: data
          mountPath: /data
  volumes:
    - name: data
      persistentVolumeClaim:
        claimName: archive-claim
EOF

kubectl wait --for=jsonpath='{.status.phase}'=Succeeded pod/seed-helper -n "$QUESTION_ID" --timeout=60s
kubectl delete pod seed-helper -n "$QUESTION_ID" --wait=true

# Delete the claim, then the PV object itself - Retain protects the
# underlying hostPath data, not this PV object's existence.
kubectl delete pvc archive-claim -n "$QUESTION_ID" --wait=true
kubectl delete pv archive-pv-old --wait=true

echo "setup.sh: $QUESTION_ID ready (retained data at /mnt/q109-46-archive has no PV object pointing at it anymore)"
