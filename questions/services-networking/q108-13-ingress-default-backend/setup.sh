#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q108-13-ingress-default-backend${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: docs-app
  labels:
    app: docs-app
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 1
  selector:
    matchLabels:
      app: docs-app
  template:
    metadata:
      labels:
        app: docs-app
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: docs-app
          image: httpd:2.4-alpine
          ports:
            - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: docs-svc
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  selector:
    app: docs-app
  ports:
    - port: 80
      targetPort: 80
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: fallback-app
  labels:
    app: fallback-app
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 1
  selector:
    matchLabels:
      app: fallback-app
  template:
    metadata:
      labels:
        app: fallback-app
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: fallback-app
          image: httpd:2.4-alpine
          ports:
            - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: fallback-svc
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  selector:
    app: fallback-app
  ports:
    - port: 80
      targetPort: 80
EOF

kubectl wait --for=condition=Available deployment/docs-app -n "$QUESTION_ID" --timeout=90s || true
kubectl wait --for=condition=Available deployment/fallback-app -n "$QUESTION_ID" --timeout=90s || true

echo "setup.sh: $QUESTION_ID ready"
