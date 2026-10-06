#!/usr/bin/env bash
# Idempotent: creates/resets the namespace, seeds the static no-class PV.
# `storageClassName: ""` is a reserved sentinel ("never dynamically
# provision") that can't be made question-unique the way a real class
# string can - a claimRef pre-binding is what protects this PV from being
# stolen by another session's own same-named "stat" claim instead.
set -euo pipefail

QUESTION_ID="q114-07-dynamic-by-default-static-on-purpose${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: q114-07-static-pv
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  capacity:
    storage: 1Gi
  accessModes: ["ReadWriteOnce"]
  storageClassName: ""
  hostPath:
    path: /mnt/q114-07-static-pv
    type: DirectoryOrCreate
  claimRef:
    namespace: $QUESTION_ID
    name: stat
EOF

echo "setup.sh: $QUESTION_ID ready"
