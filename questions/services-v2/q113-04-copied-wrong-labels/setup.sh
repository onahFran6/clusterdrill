#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q113-04-copied-wrong-labels${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: ledger
  labels:
    app: ledger
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 3
  selector:
    matchLabels:
      app: ledger-api
      tier: backend
  template:
    metadata:
      labels:
        app: ledger-api
        tier: backend
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: web
          image: nginx:1.27
          ports:
            - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: ledger-svc
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  selector:
    app: ledger
  ports:
    - port: 80
      targetPort: 8080
EOF

kubectl wait --for=condition=Available deployment/ledger -n "$QUESTION_ID" --timeout=90s || true

echo "setup.sh: $QUESTION_ID ready"
