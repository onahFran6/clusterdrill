#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q108-03-headless-service-dns${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: cache-node
  labels:
    app: cache-node
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 3
  selector:
    matchLabels:
      app: cache-node
  template:
    metadata:
      labels:
        app: cache-node
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: cache-node
          image: redis:7-alpine
          ports:
            - containerPort: 6379
EOF

kubectl wait --for=condition=Available deployment/cache-node -n "$QUESTION_ID" --timeout=90s || true

echo "setup.sh: $QUESTION_ID ready"
