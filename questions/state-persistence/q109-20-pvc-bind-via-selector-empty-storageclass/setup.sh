#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q109-20-pvc-bind-via-selector-empty-storageclass${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: vol-blue
  labels:
    clusterdrill-question: $QUESTION_ID
    env: blue
spec:
  capacity:
    storage: 100Mi
  accessModes:
    - ReadWriteOnce
  storageClassName: ""
  hostPath:
    path: /mnt/q109-20-vol-blue
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: vol-green
  labels:
    clusterdrill-question: $QUESTION_ID
    env: green
spec:
  capacity:
    storage: 100Mi
  accessModes:
    - ReadWriteOnce
  storageClassName: ""
  hostPath:
    path: /mnt/q109-20-vol-green
EOF

echo "setup.sh: $QUESTION_ID ready"
