#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q108-20-ingress-path-type-exact-vs-prefix${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: status-api
  labels:
    app: status-api
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 1
  selector:
    matchLabels:
      app: status-api
  template:
    metadata:
      labels:
        app: status-api
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: status-api
          image: httpd:2.4-alpine
          ports:
            - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: status-svc
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  selector:
    app: status-api
  ports:
    - port: 80
      targetPort: 80
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: metrics-collector
  labels:
    app: metrics-collector
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 1
  selector:
    matchLabels:
      app: metrics-collector
  template:
    metadata:
      labels:
        app: metrics-collector
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: metrics-collector
          image: httpd:2.4-alpine
          ports:
            - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: metrics-svc
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  selector:
    app: metrics-collector
  ports:
    - port: 80
      targetPort: 80
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: diagnostics-ingress
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  ingressClassName: nginx
  rules:
    - http:
        paths:
          - path: /status
            pathType: Prefix
            backend:
              service:
                name: status-svc
                port:
                  number: 80
          - path: /metrics
            pathType: Exact
            backend:
              service:
                name: metrics-svc
                port:
                  number: 80
EOF

kubectl wait --for=condition=Available deployment/status-api -n "$QUESTION_ID" --timeout=90s || true
kubectl wait --for=condition=Available deployment/metrics-collector -n "$QUESTION_ID" --timeout=90s || true

echo "setup.sh: $QUESTION_ID ready"
