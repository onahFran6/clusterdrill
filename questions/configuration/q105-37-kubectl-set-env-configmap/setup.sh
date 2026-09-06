#!/usr/bin/env bash
# Idempotent: creates/resets namespace q105-37-kubectl-set-env-configmap and
# seeds the starting ConfigMap and Deployment. Every cluster object created
# here carries the label
# clusterdrill-question=q105-37-kubectl-set-env-configmap.

set -euo pipefail

QUESTION_ID="q105-37-kubectl-set-env-configmap${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: feature-flags
  labels:
    clusterdrill-question: $QUESTION_ID
data:
  DARK_MODE: "true"
  BETA_UI: "false"
EOF

kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-frontend
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 1
  selector:
    matchLabels:
      app: web-frontend
  template:
    metadata:
      labels:
        app: web-frontend
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: web-frontend
          image: nginx:1.25-alpine
EOF

kubectl rollout status deployment/web-frontend -n "$QUESTION_ID" --timeout=60s || true

echo "setup.sh: $QUESTION_ID ready"
