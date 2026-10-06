#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q111-07-canary-shared-service-selector${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: shop-v1
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 10
  selector:
    matchLabels:
      app: shop
      version: v1
  template:
    metadata:
      labels:
        app: shop
        version: v1
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: web
          image: nginx:1.25
          ports:
            - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: shop
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  selector:
    app: shop
    version: v1
  ports:
    - port: 80
      targetPort: 80
EOF

kubectl rollout status deployment/shop-v1 -n "$QUESTION_ID" --timeout=90s || true

echo "setup.sh: $QUESTION_ID ready"
