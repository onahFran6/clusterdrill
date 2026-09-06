#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q108-10-ingress-path-based-routing${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: catalog
  labels:
    app: catalog
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 1
  selector:
    matchLabels:
      app: catalog
  template:
    metadata:
      labels:
        app: catalog
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: catalog
          image: httpd:2.4-alpine
          ports:
            - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: catalog-svc
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  selector:
    app: catalog
  ports:
    - port: 80
      targetPort: 80
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: checkout
  labels:
    app: checkout
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 1
  selector:
    matchLabels:
      app: checkout
  template:
    metadata:
      labels:
        app: checkout
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: checkout
          image: httpd:2.4-alpine
          ports:
            - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: checkout-svc
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  selector:
    app: checkout
  ports:
    - port: 80
      targetPort: 80
EOF

kubectl wait --for=condition=Available deployment/catalog -n "$QUESTION_ID" --timeout=90s || true
kubectl wait --for=condition=Available deployment/checkout -n "$QUESTION_ID" --timeout=90s || true

echo "setup.sh: $QUESTION_ID ready"
