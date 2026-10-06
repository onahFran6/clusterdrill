#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q113-08-cross-namespace-dns${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: backend
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 1
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: backend
          image: busybox:1.36
          command: ["sh", "-c", "mkdir -p /www && echo backend says hi > /www/index.html && httpd -f -p 80 -h /www"]
          ports:
            - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: backend
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  selector:
    app: backend
  ports:
    - port: 80
      targetPort: 80
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 1
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: frontend
          image: busybox:1.36
          env:
            - name: BACKEND_URL
              value: "http://backend.pollux.svc.cluster.local:80"
          command: ["sh", "-c", "while true; do wget -qO- -T 3 \$BACKEND_URL 2>&1 || echo 'call failed'; sleep 5; done"]
EOF

kubectl wait --for=condition=Available deployment/backend -n "$QUESTION_ID" --timeout=90s || true
kubectl wait --for=condition=Available deployment/frontend -n "$QUESTION_ID" --timeout=90s || true

echo "setup.sh: $QUESTION_ID ready"
