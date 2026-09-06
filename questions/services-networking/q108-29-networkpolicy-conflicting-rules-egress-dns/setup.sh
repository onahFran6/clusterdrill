#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q108-29-networkpolicy-conflicting-rules-egress-dns${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: internal-api
  labels:
    app: internal-api
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 1
  selector:
    matchLabels:
      app: internal-api
  template:
    metadata:
      labels:
        app: internal-api
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: internal-api
          image: httpd:2.4-alpine
          ports:
            - containerPort: 8080
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: report-generator-egress
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  podSelector:
    matchLabels:
      app: report-generator
  policyTypes:
    - Egress
  egress:
    - to:
        - podSelector:
            matchLabels:
              app: internal-api
      ports:
        - protocol: TCP
          port: 8080
EOF

kubectl wait --for=condition=Available deployment/report-generator -n "$QUESTION_ID" --timeout=90s || true
kubectl wait --for=condition=Available deployment/internal-api -n "$QUESTION_ID" --timeout=90s || true

echo "setup.sh: $QUESTION_ID ready"
