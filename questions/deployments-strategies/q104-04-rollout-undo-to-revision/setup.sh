#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q104-04-rollout-undo-to-revision${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: billing
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 2
  selector:
    matchLabels:
      app: billing
  template:
    metadata:
      labels:
        app: billing
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: billing
          image: nginx:1.23-alpine
EOF
kubectl rollout status deployment/billing -n "$QUESTION_ID" --timeout=60s || true

kubectl set image deployment/billing billing=nginx:1.24-alpine -n "$QUESTION_ID"
kubectl rollout status deployment/billing -n "$QUESTION_ID" --timeout=60s || true

kubectl set image deployment/billing billing=nginx:1.25-alpine -n "$QUESTION_ID"
kubectl rollout status deployment/billing -n "$QUESTION_ID" --timeout=60s || true

echo "setup.sh: $QUESTION_ID ready"
