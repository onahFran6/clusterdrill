#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q104-20-recreate-strategy-downtime${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: billing-worker
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 4
  selector:
    matchLabels:
      app: billing-worker
  template:
    metadata:
      labels:
        app: billing-worker
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: billing-worker
          image: busybox:1.36
          command: ["sh", "-c", "sleep 3600"]
EOF

kubectl rollout status deployment/billing-worker -n "$QUESTION_ID" --timeout=60s || true

echo "setup.sh: $QUESTION_ID ready"
