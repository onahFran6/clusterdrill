#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q108-21-clusterip-to-nodeport-type-change${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: catalog-api
  labels:
    app: catalog-api
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 2
  selector:
    matchLabels:
      app: catalog-api
  template:
    metadata:
      labels:
        app: catalog-api
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: catalog-api
          image: hashicorp/http-echo
          args:
            - "-listen=:5678"
            - "-text=catalog-api"
          ports:
            - containerPort: 5678
---
apiVersion: v1
kind: Service
metadata:
  name: catalog-api-svc
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  type: ClusterIP
  selector:
    app: catalog-api
  ports:
    - port: 5678
      targetPort: 5678
EOF

kubectl wait --for=condition=Available deployment/catalog-api -n "$QUESTION_ID" --timeout=90s || true

echo "setup.sh: $QUESTION_ID ready"
