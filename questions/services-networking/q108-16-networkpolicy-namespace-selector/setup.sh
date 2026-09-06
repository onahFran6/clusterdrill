#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q108-16-networkpolicy-namespace-selector${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"
kubectl label namespace "$QUESTION_ID" "team=platform" --overwrite

kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: shared-cache
  labels:
    app: shared-cache
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 1
  selector:
    matchLabels:
      app: shared-cache
  template:
    metadata:
      labels:
        app: shared-cache
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: shared-cache
          image: redis:7-alpine
          ports:
            - containerPort: 6379
EOF

kubectl wait --for=condition=Available deployment/shared-cache -n "$QUESTION_ID" --timeout=90s || true

echo "setup.sh: $QUESTION_ID ready"
