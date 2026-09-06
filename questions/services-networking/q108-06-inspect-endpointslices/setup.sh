#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q108-06-inspect-endpointslices${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: order-api
  labels:
    app: order-api
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 4
  selector:
    matchLabels:
      app: order-api
  template:
    metadata:
      labels:
        app: order-api
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: order-api
          image: httpd:2.4-alpine
          ports:
            - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: order-api-svc
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  selector:
    app: order-api
  ports:
    - port: 80
      targetPort: 80
EOF

kubectl wait --for=condition=Available deployment/order-api -n "$QUESTION_ID" --timeout=90s || true

# Give the EndpointSlice controller a moment to populate ready addresses.
for i in $(seq 1 30); do
  ready="$(kubectl get endpointslice -n "$QUESTION_ID" -l kubernetes.io/service-name=order-api-svc \
    -o jsonpath='{.items[*].endpoints[?(@.conditions.ready==true)].addresses}' 2>/dev/null)"
  [[ -n "$ready" ]] && break
  sleep 2
done

echo "setup.sh: $QUESTION_ID ready"
