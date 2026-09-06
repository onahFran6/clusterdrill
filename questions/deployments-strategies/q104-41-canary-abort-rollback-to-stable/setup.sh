#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q104-41-canary-abort-rollback-to-stable${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: search-stable
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 7
  selector:
    matchLabels:
      app: search
      track: stable
  template:
    metadata:
      labels:
        app: search
        track: stable
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: search
          image: nginx:1.24-alpine
          # Explicit, small resources: the shared namespace ResourceQuota
          # (640Mi limits.memory) can't fit 13 peak replicas (10 stable + 3
          # canary) at the LimitRange's default 128Mi/container - this
          # question needs double-digit replicas, so it opts out of the
          # default footprint instead.
          resources:
            requests:
              cpu: 10m
              memory: 16Mi
            limits:
              cpu: 50m
              memory: 32Mi
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: search-canary
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 3
  selector:
    matchLabels:
      app: search
      track: canary
  template:
    metadata:
      labels:
        app: search
        track: canary
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: search
          image: nginx:1.25-alpine
          resources:
            requests:
              cpu: 10m
              memory: 16Mi
            limits:
              cpu: 50m
              memory: 32Mi
---
apiVersion: v1
kind: Service
metadata:
  name: search-svc
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  selector:
    app: search
  ports:
    - port: 80
      targetPort: 80
EOF

kubectl rollout status deployment/search-stable -n "$QUESTION_ID" --timeout=90s || true
kubectl rollout status deployment/search-canary -n "$QUESTION_ID" --timeout=60s || true

echo "setup.sh: $QUESTION_ID ready"
