#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q104-11-blue-green-service-switch${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: web-blue
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web
      version: blue
  template:
    metadata:
      labels:
        app: web
        version: blue
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: web
          image: nginx:1.24-alpine
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-green
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web
      version: green
  template:
    metadata:
      labels:
        app: web
        version: green
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: web
          image: nginx:1.25-alpine
---
apiVersion: v1
kind: Service
metadata:
  name: web-svc
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  selector:
    app: web
    version: blue
  ports:
    - port: 80
      targetPort: 80
EOF

kubectl rollout status deployment/web-blue -n "$QUESTION_ID" --timeout=60s || true
kubectl rollout status deployment/web-green -n "$QUESTION_ID" --timeout=60s || true

echo "setup.sh: $QUESTION_ID ready"
