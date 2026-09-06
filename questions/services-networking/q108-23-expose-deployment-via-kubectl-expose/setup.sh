#!/usr/bin/env bash
# Idempotent: creates/resets namespace and seeds a bare Deployment with no
# Service in front of it. Every object created here - namespaced or
# cluster-scoped - carries the label clusterdrill-question=$QUESTION_ID.

set -euo pipefail

QUESTION_ID="q108-23-expose-deployment-via-kubectl-expose${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: billing-worker
  labels:
    app: billing-worker
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 3
  selector:
    matchLabels:
      app: billing-worker
  template:
    metadata:
      labels:
        app: billing-worker
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: billing-worker
          image: httpd:2.4-alpine
          ports:
            - containerPort: 8443
          resources:
            requests:
              cpu: 25m
              memory: 32Mi
            limits:
              cpu: 50m
              memory: 64Mi
EOF

kubectl wait --for=condition=Available deployment/billing-worker -n "$QUESTION_ID" --timeout=90s || true

echo "setup.sh: $QUESTION_ID ready"
