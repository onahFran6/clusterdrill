#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q104-36-scale-via-patch-merge${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: session-store
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 3
  selector:
    matchLabels:
      app: session-store
  template:
    metadata:
      labels:
        app: session-store
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        # Explicit, small resources: scaling to 6 replicas at the
        # LimitRange's default 128Mi/container is 768Mi of limits.memory,
        # over the namespace ResourceQuota's 640Mi cap.
        - name: session-store
          image: memcached:1.6-alpine
          resources:
            requests:
              cpu: 10m
              memory: 16Mi
            limits:
              cpu: 50m
              memory: 32Mi
EOF

kubectl rollout status deployment/session-store -n "$QUESTION_ID" --timeout=60s || true

echo "setup.sh: $QUESTION_ID ready (session-store at 3/3 ready replicas)"
