#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q109-34-fix-pvc-storageclassname-typo${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: reports-data
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: standrd
  resources:
    requests:
      storage: 100Mi
EOF

echo "setup.sh: $QUESTION_ID ready"
