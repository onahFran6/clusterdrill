#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q108-43-service-internaltrafficpolicy-local${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: metrics-sidecar
  labels:
    app: metrics-sidecar
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 2
  selector:
    matchLabels:
      app: metrics-sidecar
  template:
    metadata:
      labels:
        app: metrics-sidecar
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: metrics-sidecar
          image: httpd:2.4-alpine
          ports:
            - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: metrics-sidecar-svc
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  type: ClusterIP
  selector:
    app: metrics-sidecar
  ports:
    - port: 80
      targetPort: 80
EOF

kubectl wait --for=condition=Available deployment/metrics-sidecar -n "$QUESTION_ID" --timeout=90s || true

echo "setup.sh: $QUESTION_ID ready"
