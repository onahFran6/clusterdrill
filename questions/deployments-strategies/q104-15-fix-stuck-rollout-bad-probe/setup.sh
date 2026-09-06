#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q104-15-fix-stuck-rollout-bad-probe${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: checkout-api
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 3
  selector:
    matchLabels:
      app: checkout-api
  template:
    metadata:
      labels:
        app: checkout-api
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: checkout-api
          image: nginx:1.24-alpine
EOF
kubectl rollout status deployment/checkout-api -n "$QUESTION_ID" --timeout=60s || true

kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: checkout-api
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 3
  selector:
    matchLabels:
      app: checkout-api
  template:
    metadata:
      labels:
        app: checkout-api
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: checkout-api
          image: nginx:1.25-alpine
          readinessProbe:
            httpGet:
              path: /does-not-exist
              port: 80
            periodSeconds: 2
            failureThreshold: 1
EOF

# Give the broken rollout a moment to actually get stuck (first new pod
# comes up but never passes readiness) before handing this to the candidate.
sleep 10

echo "setup.sh: $QUESTION_ID ready (rollout stuck on a broken readiness probe)"
