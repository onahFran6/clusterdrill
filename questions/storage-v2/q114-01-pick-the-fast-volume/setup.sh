#!/usr/bin/env bash
# Idempotent: creates/resets the namespace, seeds two static PVs. The PVC
# and Pod are built by the candidate - nothing else is seeded.
set -euo pipefail

QUESTION_ID="q114-01-pick-the-fast-volume${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: q114-01-fast-pv
  labels:
    clusterdrill-question: $QUESTION_ID
    tier: fast
spec:
  capacity:
    storage: 1Gi
  accessModes: ["ReadWriteOnce"]
  storageClassName: manual-q114-01
  hostPath:
    path: /mnt/q114-01-fast-pv
    type: DirectoryOrCreate
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: q114-01-slow-pv
  labels:
    clusterdrill-question: $QUESTION_ID
    tier: slow
spec:
  capacity:
    storage: 1Gi
  accessModes: ["ReadWriteOnce"]
  storageClassName: manual-q114-01
  hostPath:
    path: /mnt/q114-01-slow-pv
    type: DirectoryOrCreate
EOF

echo "setup.sh: $QUESTION_ID ready"
