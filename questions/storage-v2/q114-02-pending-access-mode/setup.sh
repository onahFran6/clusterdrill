#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q114-02-pending-access-mode${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: q114-02-pv
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  capacity:
    storage: 2Gi
  accessModes: ["ReadWriteOnce"]
  storageClassName: manual-q114-02
  hostPath:
    path: /mnt/q114-02-pv
    type: DirectoryOrCreate
EOF

kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: amazon-pvc
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  storageClassName: manual-q114-02
  accessModes: ["ReadWriteMany"]
  resources:
    requests:
      storage: 1Gi
EOF

echo "setup.sh: $QUESTION_ID ready"
