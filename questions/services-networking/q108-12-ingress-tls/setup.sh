#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q108-12-ingress-tls${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: secure-app
  labels:
    app: secure-app
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 1
  selector:
    matchLabels:
      app: secure-app
  template:
    metadata:
      labels:
        app: secure-app
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: secure-app
          image: httpd:2.4-alpine
          ports:
            - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: secure-app-svc
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  selector:
    app: secure-app
  ports:
    - port: 80
      targetPort: 80
EOF

# Self-signed cert/key for the TLS Secret - generated fresh each run so
# setup.sh has no external file dependency and stays idempotent (kubectl
# apply on the resulting Secret just replaces it with an equally-valid pair).
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT
openssl req -x509 -nodes -newkey rsa:2048 \
  -keyout "$TMP_DIR/tls.key" -out "$TMP_DIR/tls.crt" -days 365 \
  -subj "/CN=secure.ckad.example.com/O=clusterdrill" \
  -addext "subjectAltName=DNS:secure.ckad.example.com" >/dev/null 2>&1

kubectl create secret tls secure-app-tls \
  -n "$QUESTION_ID" \
  --cert="$TMP_DIR/tls.crt" --key="$TMP_DIR/tls.key" \
  --dry-run=client -o yaml \
  | kubectl label -f - --local -o yaml "clusterdrill-question=$QUESTION_ID" \
  | kubectl apply -f -

kubectl wait --for=condition=Available deployment/secure-app -n "$QUESTION_ID" --timeout=90s || true

echo "setup.sh: $QUESTION_ID ready"
