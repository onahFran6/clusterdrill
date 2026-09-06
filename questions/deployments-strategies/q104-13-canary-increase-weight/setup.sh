#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q104-13-canary-increase-weight${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: payments-stable
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 9
  selector:
    matchLabels:
      app: payments
      track: stable
  template:
    metadata:
      labels:
        app: payments
        track: stable
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: payments
          image: nginx:1.24-alpine
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: payments-canary
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 1
  selector:
    matchLabels:
      app: payments
      track: canary
  template:
    metadata:
      labels:
        app: payments
        track: canary
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: payments
          image: nginx:1.25-alpine
---
apiVersion: v1
kind: Service
metadata:
  name: payments-svc
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  selector:
    app: payments
  ports:
    - port: 80
      targetPort: 80
EOF

kubectl rollout status deployment/payments-stable -n "$QUESTION_ID" --timeout=90s || true
kubectl rollout status deployment/payments-canary -n "$QUESTION_ID" --timeout=60s || true

echo "setup.sh: $QUESTION_ID ready"
