#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q108-40-service-add-second-selector-key-fix${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: payment-worker
  labels:
    app: payment-worker
    tier: backend
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 2
  selector:
    matchLabels:
      app: payment-worker
      tier: backend
  template:
    metadata:
      labels:
        app: payment-worker
        tier: backend
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: payment-worker
          image: httpd:2.4-alpine
          ports:
            - containerPort: 80
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: payment-worker-canary
  labels:
    app: payment-worker
    tier: canary
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 1
  selector:
    matchLabels:
      app: payment-worker
      tier: canary
  template:
    metadata:
      labels:
        app: payment-worker
        tier: canary
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: payment-worker
          image: httpd:2.4-alpine
          ports:
            - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: payment-worker-svc
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  selector:
    app: payment-worker
  ports:
    - port: 80
      targetPort: 80
EOF

kubectl wait --for=condition=Available deployment/payment-worker -n "$QUESTION_ID" --timeout=90s || true
kubectl wait --for=condition=Available deployment/payment-worker-canary -n "$QUESTION_ID" --timeout=90s || true

echo "setup.sh: $QUESTION_ID ready"
