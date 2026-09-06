#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q104-12-canary-shared-selector-split${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: orders-stable
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 9
  selector:
    matchLabels:
      app: orders
      track: stable
  template:
    metadata:
      labels:
        app: orders
        track: stable
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: orders
          image: nginx:1.24-alpine
---
apiVersion: v1
kind: Service
metadata:
  name: orders-svc
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  selector:
    app: orders
  ports:
    - port: 80
      targetPort: 80
EOF

kubectl rollout status deployment/orders-stable -n "$QUESTION_ID" --timeout=90s || true

echo "setup.sh: $QUESTION_ID ready"
