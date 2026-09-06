#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q109-40-pvc-stuck-terminating-pod-still-attached${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: session-cache
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: standard
  resources:
    requests:
      storage: 50Mi
---
apiVersion: v1
kind: Pod
metadata:
  name: session-worker
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  containers:
    - name: session-worker
      image: busybox:1.36
      command: ["sh", "-c", "sleep 3600"]
      volumeMounts:
        - name: cache
          mountPath: /cache
  volumes:
    - name: cache
      persistentVolumeClaim:
        claimName: session-cache
EOF

kubectl wait --for=condition=Ready pod/session-worker -n "$QUESTION_ID" --timeout=90s || true

# Delete the PVC with --wait=false while the Pod still references it - the
# kubernetes.io/pvc-protection finalizer blocks the actual removal, so this
# leaves it stuck Terminating instead of hanging this script forever.
kubectl delete pvc session-cache -n "$QUESTION_ID" --wait=false

echo "setup.sh: $QUESTION_ID ready (PVC 'session-cache' stuck Terminating - session-worker still references it)"
