#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q108-15-networkpolicy-allow-egress-to-pods${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: report-generator
  labels:
    app: report-generator
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 1
  selector:
    matchLabels:
      app: report-generator
  template:
    metadata:
      labels:
        app: report-generator
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: report-generator
          image: httpd:2.4-alpine
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: metrics-store
  labels:
    app: metrics-store
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 1
  selector:
    matchLabels:
      app: metrics-store
  template:
    metadata:
      labels:
        app: metrics-store
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: metrics-store
          image: httpd:2.4-alpine
          ports:
            - containerPort: 9090
EOF

kubectl wait --for=condition=Available deployment/report-generator -n "$QUESTION_ID" --timeout=90s || true
kubectl wait --for=condition=Available deployment/metrics-store -n "$QUESTION_ID" --timeout=90s || true

echo "setup.sh: $QUESTION_ID ready"
