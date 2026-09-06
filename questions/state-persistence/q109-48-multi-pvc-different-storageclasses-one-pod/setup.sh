#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q109-48-multi-pvc-different-storageclasses-one-pod${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

kubectl apply -f - <<EOF
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fast-tier
  labels:
    clusterdrill-question: $QUESTION_ID
provisioner: k8s.io/minikube-hostpath
reclaimPolicy: Delete
---
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: durable-tier
  labels:
    clusterdrill-question: $QUESTION_ID
provisioner: k8s.io/minikube-hostpath
reclaimPolicy: Retain
EOF

echo "setup.sh: $QUESTION_ID ready"
