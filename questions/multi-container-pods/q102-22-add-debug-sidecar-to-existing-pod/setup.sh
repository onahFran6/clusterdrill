#!/usr/bin/env bash
# Idempotent: creates/resets namespace and seeds a single-container
# "billing-api" Deployment (1 replica, already Running) that the candidate
# must extend with a second "net-debug" container in place.
set -euo pipefail

QUESTION_ID="q102-22-add-debug-sidecar-to-existing-pod${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: billing-api
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 1
  selector:
    matchLabels:
      app: billing-api
  template:
    metadata:
      labels:
        app: billing-api
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: billing-api
          image: nginx:1.25
          resources:
            requests:
              cpu: 25m
              memory: 32Mi
            limits:
              cpu: 50m
              memory: 64Mi
EOF

kubectl rollout status deployment/billing-api -n "$QUESTION_ID" --timeout=60s >/dev/null

echo "setup.sh: $QUESTION_ID ready"
