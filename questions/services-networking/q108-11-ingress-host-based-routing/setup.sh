#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q108-11-ingress-host-based-routing${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: blog
  labels:
    app: blog
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 1
  selector:
    matchLabels:
      app: blog
  template:
    metadata:
      labels:
        app: blog
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: blog
          image: httpd:2.4-alpine
          ports:
            - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: blog-svc
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  selector:
    app: blog
  ports:
    - port: 80
      targetPort: 80
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api
  labels:
    app: api
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 1
  selector:
    matchLabels:
      app: api
  template:
    metadata:
      labels:
        app: api
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: api
          image: httpd:2.4-alpine
          ports:
            - containerPort: 8080
EOF

kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: api-svc
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  selector:
    app: api
  ports:
    - port: 8080
      targetPort: 8080
EOF

kubectl wait --for=condition=Available deployment/blog -n "$QUESTION_ID" --timeout=90s || true
kubectl wait --for=condition=Available deployment/api -n "$QUESTION_ID" --timeout=90s || true

echo "setup.sh: $QUESTION_ID ready"
