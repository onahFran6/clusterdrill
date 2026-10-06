#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q114-03-which-size-wins${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

for pair in "q114-03-1g:1Gi" "q114-03-5g:5Gi" "q114-03-10g:10Gi"; do
  name="${pair%%:*}"
  size="${pair##*:}"
  kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolume
metadata:
  name: $name
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  capacity:
    storage: $size
  accessModes: ["ReadWriteOnce"]
  storageClassName: manual-q114-03
  hostPath:
    path: /mnt/$name
    type: DirectoryOrCreate
EOF
done

echo "setup.sh: $QUESTION_ID ready"
