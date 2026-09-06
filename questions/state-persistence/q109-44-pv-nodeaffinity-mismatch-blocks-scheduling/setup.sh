#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q109-44-pv-nodeaffinity-mismatch-blocks-scheduling${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

# A `local` PersistentVolume requires the directory to already exist on the
# node - use a short-lived pod (portable across whatever driver backs the
# node) to create it, then delete the pod.
kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: provision-helper
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  restartPolicy: Never
  containers:
    - name: provision-helper
      image: busybox:1.36
      command: ["sh", "-c", "mkdir -p /mnt/q109-44-metrics && chmod 777 /mnt/q109-44-metrics"]
      volumeMounts:
        - name: hostmnt
          mountPath: /mnt
  volumes:
    - name: hostmnt
      hostPath:
        path: /mnt
EOF

kubectl wait --for=jsonpath='{.status.phase}'=Succeeded pod/provision-helper -n "$QUESTION_ID" --timeout=60s
kubectl delete pod provision-helper -n "$QUESTION_ID" --wait=true

kubectl apply -f - <<EOF
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: local-storage-q109-44
  labels:
    clusterdrill-question: $QUESTION_ID
provisioner: kubernetes.io/no-provisioner
volumeBindingMode: WaitForFirstConsumer
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: metrics-local-pv
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  capacity:
    storage: 100Mi
  volumeMode: Filesystem
  accessModes:
    - ReadWriteOnce
  storageClassName: local-storage-q109-44
  local:
    path: /mnt/q109-44-metrics
  nodeAffinity:
    required:
      nodeSelectorTerms:
        - matchExpressions:
            - key: kubernetes.io/hostname
              operator: In
              values:
                - ckad-worker-99
EOF

kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: metrics-claim
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: local-storage-q109-44
  resources:
    requests:
      storage: 100Mi
---
apiVersion: v1
kind: Pod
metadata:
  name: metrics-collector
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  containers:
    - name: metrics-collector
      image: busybox:1.36
      command: ["sh", "-c", "sleep 3600"]
      volumeMounts:
        - name: data
          mountPath: /data
  volumes:
    - name: data
      persistentVolumeClaim:
        claimName: metrics-claim
EOF

echo "setup.sh: $QUESTION_ID ready (metrics-collector stuck Pending - metrics-local-pv's nodeAffinity names a node that doesn't exist)"
