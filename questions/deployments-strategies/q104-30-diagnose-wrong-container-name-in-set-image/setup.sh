#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q104-30-diagnose-wrong-container-name-in-set-image${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: search-api
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 2
  selector:
    matchLabels:
      app: search-api
  template:
    metadata:
      labels:
        app: search-api
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: search-api
          image: nginx:1.25-alpine
EOF

kubectl rollout status deployment/search-api -n "$QUESTION_ID" --timeout=60s

echo "setup.sh: $QUESTION_ID ready"
