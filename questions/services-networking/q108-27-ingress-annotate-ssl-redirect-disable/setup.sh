#!/usr/bin/env bash
# Idempotent: creates/resets namespace q108-27-ingress-annotate-ssl-redirect-disable
# and seeds a plain-HTTP Ingress that was misconfigured with the
# force-ssl-redirect annotation set to "true".

set -euo pipefail

QUESTION_ID="q108-27-ingress-annotate-ssl-redirect-disable${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: docs
  labels:
    app: docs
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 1
  selector:
    matchLabels:
      app: docs
  template:
    metadata:
      labels:
        app: docs
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: docs
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
    app: docs
  ports:
    - port: 80
      targetPort: 80
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: docs-ingress
  labels:
    clusterdrill-question: $QUESTION_ID
  annotations:
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
spec:
  ingressClassName: nginx
  rules:
    - http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: docs-svc
                port:
                  number: 80
EOF

kubectl wait --for=condition=Available deployment/docs -n "$QUESTION_ID" --timeout=90s || true

echo "setup.sh: $QUESTION_ID ready"
