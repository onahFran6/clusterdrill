#!/usr/bin/env bash
# Idempotent: creates/resets namespace
# q101-46-fix-stuck-rollout-bad-readiness-probe and seeds a Deployment whose
# readinessProbe points at a path nginx doesn't serve (404), so every pod
# stays Running but never Ready and the Deployment never finishes rolling
# out - until the candidate fixes the probe path.

set -euo pipefail

QUESTION_ID="q101-46-fix-stuck-rollout-bad-readiness-probe${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: web-front
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web-front
  template:
    metadata:
      labels:
        app: web-front
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: web-front
          image: nginx:1.25-alpine
          ports:
            - containerPort: 80
          readinessProbe:
            httpGet:
              path: /this-path-does-not-exist
              port: 80
            periodSeconds: 2
            failureThreshold: 2
          resources:
            requests:
              cpu: 25m
              memory: 32Mi
            limits:
              cpu: 50m
              memory: 64Mi
EOF

kubectl rollout status deployment/web-front -n "$QUESTION_ID" --timeout=20s || true

echo "setup.sh: $QUESTION_ID ready"
