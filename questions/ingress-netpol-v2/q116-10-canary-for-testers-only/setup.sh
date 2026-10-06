#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q116-10-canary-for-testers-only${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: stable
  labels:
    app: stable
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 1
  selector:
    matchLabels:
      app: stable
  template:
    metadata:
      labels:
        app: stable
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: stable
          image: hashicorp/http-echo:1.0
          args: ["-listen=:5678", "-text=stable"]
          ports:
            - containerPort: 5678
---
apiVersion: v1
kind: Service
metadata:
  name: stable-svc
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  selector:
    app: stable
  ports:
    - port: 80
      targetPort: 5678
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: canary
  labels:
    app: canary
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 1
  selector:
    matchLabels:
      app: canary
  template:
    metadata:
      labels:
        app: canary
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: canary
          image: hashicorp/http-echo:1.0
          args: ["-listen=:5678", "-text=canary"]
          ports:
            - containerPort: 5678
---
apiVersion: v1
kind: Service
metadata:
  name: canary-svc
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  selector:
    app: canary
  ports:
    - port: 80
      targetPort: 5678
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: comet
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  ingressClassName: nginx
  rules:
    - host: comet.local
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: stable-svc
                port:
                  number: 80
EOF

kubectl wait --for=condition=Available deployment/stable -n "$QUESTION_ID" --timeout=90s || true
kubectl wait --for=condition=Available deployment/canary -n "$QUESTION_ID" --timeout=90s || true

echo "setup.sh: $QUESTION_ID ready"
