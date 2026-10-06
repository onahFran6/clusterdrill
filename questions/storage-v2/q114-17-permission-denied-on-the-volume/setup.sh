#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q114-17-permission-denied-on-the-volume${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

# A hostPath volume's directory lives on the node's own disk, outside
# Kubernetes entirely - full_reset only deletes API objects, so a prior
# solve's chown to 1000:2000 would otherwise survive forever on the node
# and silently hand the next "unsolved" run a pre-fixed directory. Reset
# it to root-owned 0700 every time, via the same short-lived privileged
# pod pattern q114-06 uses to create node directories.
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: ${QUESTION_ID}-reset-perms
  namespace: $QUESTION_ID
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  restartPolicy: Never
  containers:
    - name: reset
      image: busybox:1.36
      command: ["sh", "-c", "rm -rf /mnt/q114-17-pv && mkdir -p /mnt/q114-17-pv && chown 0:0 /mnt/q114-17-pv && chmod 700 /mnt/q114-17-pv"]
      securityContext:
        runAsUser: 0
      volumeMounts:
        - name: hostmnt
          mountPath: /mnt
  volumes:
    - name: hostmnt
      hostPath:
        path: /mnt
EOF

kubectl wait --for=jsonpath='{.status.phase}'=Succeeded "pod/${QUESTION_ID}-reset-perms" \
  --namespace="$QUESTION_ID" --timeout=60s
kubectl delete pod "${QUESTION_ID}-reset-perms" --namespace="$QUESTION_ID" --ignore-not-found

kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolume
metadata:
  name: q114-17-pv
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  capacity:
    storage: 1Gi
  accessModes: ["ReadWriteOnce"]
  storageClassName: manual-q114-17
  hostPath:
    path: /mnt/q114-17-pv
    type: DirectoryOrCreate
EOF

kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: uploads
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  storageClassName: manual-q114-17
  volumeName: q114-17-pv
  accessModes: ["ReadWriteOnce"]
  resources:
    requests:
      storage: 1Gi
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: uploader
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 1
  selector:
    matchLabels:
      app: uploader
  template:
    metadata:
      labels:
        app: uploader
        clusterdrill-question: $QUESTION_ID
    spec:
      securityContext:
        runAsUser: 1000
        fsGroup: 2000
      volumes:
        - name: d
          persistentVolumeClaim:
            claimName: uploads
      containers:
        - name: up
          image: busybox:1.36
          command: ["sh", "-c", "date > /data/upload.txt && sleep 3600"]
          volumeMounts:
            - name: d
              mountPath: /data
EOF

echo "setup.sh: $QUESTION_ID ready"
