#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q104-35-basic-image-update-set-image${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: web-cache
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web-cache
  template:
    metadata:
      labels:
        app: web-cache
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: web-cache
          image: redis:7.2-alpine
EOF

kubectl rollout status deployment/web-cache -n "$QUESTION_ID" --timeout=60s || true

echo "setup.sh: $QUESTION_ID ready (web-cache at 3/3 ready replicas on redis:7.2-alpine)"
