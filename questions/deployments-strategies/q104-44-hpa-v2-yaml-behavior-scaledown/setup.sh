#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q104-44-hpa-v2-yaml-behavior-scaledown${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: render-farm
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 3
  selector:
    matchLabels:
      app: render-farm
  template:
    metadata:
      labels:
        app: render-farm
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: render-farm
          image: nginx:1.25-alpine
          resources:
            requests:
              cpu: 100m
EOF

kubectl rollout status deployment/render-farm -n "$QUESTION_ID" --timeout=60s || true

echo "setup.sh: $QUESTION_ID ready (render-farm at 3/3 ready replicas, no HPA yet)"
