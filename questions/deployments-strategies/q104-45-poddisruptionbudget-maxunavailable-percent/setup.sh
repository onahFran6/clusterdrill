#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q104-45-poddisruptionbudget-maxunavailable-percent${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: catalog-svc
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 5
  selector:
    matchLabels:
      app: catalog-svc
  template:
    metadata:
      labels:
        app: catalog-svc
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: catalog-svc
          image: busybox:1.36
          command: ["sleep", "3600"]
EOF

kubectl rollout status deployment/catalog-svc -n "$QUESTION_ID" --timeout=60s || true

echo "setup.sh: $QUESTION_ID ready (catalog-svc at 5/5 ready replicas, no PDB yet)"
