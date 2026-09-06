#!/usr/bin/env bash
# Idempotent: creates/resets namespace and seeds a working Deployment/Service
# fronted by an Ingress whose /pay backend references a service port *name*
# that does not exist on the Service (missing "-api" suffix), causing 502s.
set -euo pipefail

QUESTION_ID="q108-30-ingress-multiple-backends-wrong-service-port-name${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: payments-app
  labels:
    app: payments-app
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 1
  selector:
    matchLabels:
      app: payments-app
  template:
    metadata:
      labels:
        app: payments-app
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: payments-app
          image: hashicorp/http-echo:1.0
          args:
            - "-listen=:8080"
            - "-text=payments-ok"
          ports:
            - containerPort: 8080
          resources:
            requests:
              cpu: 25m
              memory: 32Mi
            limits:
              cpu: 50m
              memory: 64Mi
---
apiVersion: v1
kind: Service
metadata:
  name: payments-svc
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  selector:
    app: payments-app
  ports:
    - name: http-api
      port: 80
      targetPort: 8080
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: payments-ingress
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  ingressClassName: nginx
  rules:
    - http:
        paths:
          - path: /pay
            pathType: Prefix
            backend:
              service:
                name: payments-svc
                port:
                  name: http
EOF

kubectl wait --for=condition=Available deployment/payments-app -n "$QUESTION_ID" --timeout=90s || true

echo "setup.sh: $QUESTION_ID ready"
