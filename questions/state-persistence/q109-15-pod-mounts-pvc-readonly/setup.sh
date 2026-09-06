#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q109-15-pod-mounts-pvc-readonly${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

mkdir -p /tmp/ckad-readonly-pv

kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolume
metadata:
  name: readonly-pv
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  capacity:
    storage: 100Mi
  accessModes:
    - ReadWriteOnce
  storageClassName: ""
  hostPath:
    path: /tmp/ckad-readonly-pv
EOF

kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: readonly-claim
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: ""
  volumeName: readonly-pv
  resources:
    requests:
      storage: 100Mi
EOF

kubectl wait --for=jsonpath='{.status.phase}'=Bound pvc/readonly-claim -n "$QUESTION_ID" --timeout=60s || true

kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: reader-app
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  containers:
    - name: reader
      image: busybox:1.36
      command: ["sh", "-c", "sleep 3600"]
EOF

kubectl wait --for=condition=Ready pod/reader-app -n "$QUESTION_ID" --timeout=60s || true

echo "setup.sh: $QUESTION_ID ready"
