#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q104-18-scale-during-rollout${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: media-transcoder
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 4
  selector:
    matchLabels:
      app: media-transcoder
  template:
    metadata:
      labels:
        app: media-transcoder
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: media-transcoder
          image: nginx:1.24-alpine
EOF
kubectl rollout status deployment/media-transcoder -n "$QUESTION_ID" --timeout=60s || true

kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: media-transcoder
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 4
  selector:
    matchLabels:
      app: media-transcoder
  template:
    metadata:
      labels:
        app: media-transcoder
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: media-transcoder
          image: nginx:1.25-alpine
          readinessProbe:
            httpGet:
              path: /does-not-exist
              port: 80
            periodSeconds: 2
            failureThreshold: 1
EOF

sleep 10

echo "setup.sh: $QUESTION_ID ready (rollout intentionally stuck mid-progress)"
