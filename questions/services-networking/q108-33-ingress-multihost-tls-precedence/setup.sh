#!/usr/bin/env bash
# Idempotent: creates/resets namespace and seeds two Deployment/Service
# pairs, two host-specific TLS Secrets, and one multi-host Ingress whose
# spec.tls entry for api.shop.example.local was copy-pasted from the
# shop.example.local entry and never repointed at its own Secret - so
# ingress-nginx falls back to its default self-signed cert for that host
# instead of serving shop-api-tls. HTTP host routing (spec.rules) is left
# correct; only the TLS secretName mapping is broken.
set -euo pipefail

QUESTION_ID="q108-33-ingress-multihost-tls-precedence${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: shop-web
  labels:
    app: shop-web
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 1
  selector:
    matchLabels:
      app: shop-web
  template:
    metadata:
      labels:
        app: shop-web
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: shop-web
          image: hashicorp/http-echo:1.0
          args:
            - "-listen=:8080"
            - "-text=shop-web-ok"
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
  name: shop-web-svc
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  selector:
    app: shop-web
  ports:
    - port: 80
      targetPort: 8080
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: shop-api
  labels:
    app: shop-api
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 1
  selector:
    matchLabels:
      app: shop-api
  template:
    metadata:
      labels:
        app: shop-api
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: shop-api
          image: hashicorp/http-echo:1.0
          args:
            - "-listen=:8080"
            - "-text=shop-api-ok"
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
  name: shop-api-svc
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  selector:
    app: shop-api
  ports:
    - port: 80
      targetPort: 8080
EOF

# Self-signed cert/key pairs, one per host, generated fresh each run so
# setup.sh has no external file dependency and stays idempotent.
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

openssl req -x509 -nodes -newkey rsa:2048 \
  -keyout "$TMP_DIR/web.key" -out "$TMP_DIR/web.crt" -days 365 \
  -subj "/CN=shop.example.local/O=clusterdrill" \
  -addext "subjectAltName=DNS:shop.example.local" >/dev/null 2>&1

openssl req -x509 -nodes -newkey rsa:2048 \
  -keyout "$TMP_DIR/api.key" -out "$TMP_DIR/api.crt" -days 365 \
  -subj "/CN=api.shop.example.local/O=clusterdrill" \
  -addext "subjectAltName=DNS:api.shop.example.local" >/dev/null 2>&1

kubectl create secret tls shop-web-tls \
  -n "$QUESTION_ID" \
  --cert="$TMP_DIR/web.crt" --key="$TMP_DIR/web.key" \
  --dry-run=client -o yaml \
  | kubectl label -f - --local -o yaml "clusterdrill-question=$QUESTION_ID" \
  | kubectl apply -f -

kubectl create secret tls shop-api-tls \
  -n "$QUESTION_ID" \
  --cert="$TMP_DIR/api.crt" --key="$TMP_DIR/api.key" \
  --dry-run=client -o yaml \
  | kubectl label -f - --local -o yaml "clusterdrill-question=$QUESTION_ID" \
  | kubectl apply -f -

# The bug: spec.tls[1].secretName still says "shop-web-tls" (copy-pasted
# from the shop.example.local entry above it) instead of "shop-api-tls".
# spec.rules for both hosts is already correct and must stay untouched.
kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: shop-ingress
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  ingressClassName: nginx
  tls:
    - hosts:
        - shop.example.local
      secretName: shop-web-tls
    - hosts:
        - api.shop.example.local
      secretName: shop-web-tls
  rules:
    - host: shop.example.local
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: shop-web-svc
                port:
                  number: 80
    - host: api.shop.example.local
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: shop-api-svc
                port:
                  number: 80
EOF

kubectl wait --for=condition=Available deployment/shop-web -n "$QUESTION_ID" --timeout=90s || true
kubectl wait --for=condition=Available deployment/shop-api -n "$QUESTION_ID" --timeout=90s || true

echo "setup.sh: $QUESTION_ID ready"
