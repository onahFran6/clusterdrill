#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q111-14-config-secret-volumes-and-downward-api${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: gateway-conf
  labels:
    clusterdrill-question: $QUESTION_ID
data:
  default.conf: |
    server {
      listen 80;
      location / { return 200 "gateway ok\n"; }
    }
---
apiVersion: v1
kind: Secret
metadata:
  name: gateway-key
  labels:
    clusterdrill-question: $QUESTION_ID
stringData:
  api.key: k3y-9f2
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: gateway
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 2
  selector:
    matchLabels:
      app: gateway
  template:
    metadata:
      labels:
        app: gateway
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: nginx
          image: nginx:1.27
EOF

kubectl rollout status deployment/gateway -n "$QUESTION_ID" --timeout=60s || true

echo "setup.sh: $QUESTION_ID ready"
