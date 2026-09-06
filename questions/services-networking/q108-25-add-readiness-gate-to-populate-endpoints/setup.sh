#!/usr/bin/env bash
# Idempotent: creates/resets namespace and seeds a Deployment whose
# readinessProbe points at a path nginx never serves, so pods stay Running
# but never Ready and the fronting Service has zero ready endpoints.

set -euo pipefail

QUESTION_ID="q108-25-add-readiness-gate-to-populate-endpoints${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: search-index
  labels:
    app: search-index
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 2
  selector:
    matchLabels:
      app: search-index
  template:
    metadata:
      labels:
        app: search-index
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: search-index
          image: nginx:1.25
          ports:
            - containerPort: 80
          readinessProbe:
            httpGet:
              path: /health
              port: 80
            initialDelaySeconds: 1
            periodSeconds: 3
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
  name: search-index-svc
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  selector:
    app: search-index
  ports:
    - port: 80
      targetPort: 80
EOF

kubectl wait --for=condition=Available deployment/search-index -n "$QUESTION_ID" --timeout=30s 2>/dev/null || true

echo "setup.sh: $QUESTION_ID ready"
