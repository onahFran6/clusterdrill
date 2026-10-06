#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q111-13-log-sidecar-independent-update${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: orders
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 1
  selector:
    matchLabels:
      app: orders
  template:
    metadata:
      labels:
        app: orders
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: app
          image: busybox:1.36
          command:
            - sh
            - -c
            - 'mkdir -p /var/log/app; while true; do echo "$(date) order placed" >> /var/log/app/orders.log; sleep 5; done'
EOF

kubectl rollout status deployment/orders -n "$QUESTION_ID" --timeout=60s || true

echo "setup.sh: $QUESTION_ID ready"
