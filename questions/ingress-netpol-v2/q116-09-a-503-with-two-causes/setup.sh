#!/usr/bin/env bash
# This question needs a second namespace (where the Ingress was mistakenly
# created). Per the established pattern for multi-namespace questions in
# this bank (see q108-28-diagnose-dns-wrong-namespace-suffix), WRONG_NS
# below is named as a suffix of $QUESTION_ID, but neither the namespace nor
# the Ingress inside it carries the clusterdrill-question label (full_reset
# never sweeps other namespaces, so labeling it would make it look
# permanently "leaked" instead of cleaned up). setup.sh is instead
# responsible for its own idempotency by deleting and recreating WRONG_NS
# wholesale on every run.
set -euo pipefail

QUESTION_ID="q116-09-a-503-with-two-causes${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
WRONG_NS="${QUESTION_ID}-wrong"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

kubectl delete namespace "$WRONG_NS" --ignore-not-found --wait=true >/dev/null 2>&1
kubectl create namespace "$WRONG_NS" \
  --dry-run=client -o yaml | kubectl apply -f -
apply_default_resource_limits "$WRONG_NS"
grant_user_namespace_access "$WRONG_NS" "${CLUSTERDRILL_USER_ID:-}"

# Real app, with a Service whose selector deliberately matches nothing
# (app=web-app instead of the pods' real app=web) - fault #2.
kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web
  labels:
    app: web
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 1
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: web
          image: hashicorp/http-echo:1.0
          args: ["-listen=:5678", "-text=web"]
          ports:
            - containerPort: 5678
---
apiVersion: v1
kind: Service
metadata:
  name: web-svc
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  selector:
    app: web-app
  ports:
    - port: 80
      targetPort: 5678
EOF

# Fault #1: the Ingress lives in the WRONG namespace, so its backend
# (web-svc, no namespace field) can never resolve to the real Service.
kubectl apply -n "$WRONG_NS" -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: eclipse
spec:
  ingressClassName: nginx
  rules:
    - host: eclipse.local
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: web-svc
                port:
                  number: 80
EOF

kubectl wait --for=condition=Available deployment/web -n "$QUESTION_ID" --timeout=90s || true

echo "setup.sh: $QUESTION_ID ready (Ingress mistakenly created in $WRONG_NS)"
