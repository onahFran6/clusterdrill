#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q108-51-networkpolicy-additive-allow-overrides-deny${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: api
  labels:
    app: api
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 1
  selector:
    matchLabels:
      app: api
  template:
    metadata:
      labels:
        app: api
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: api
          image: busybox:1.36
          command: ["sh", "-c", "sleep 3600"]
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: api-deny-all-ingress
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  podSelector:
    matchLabels:
      app: api
  policyTypes:
    - Ingress
EOF

kubectl wait --for=condition=Available deployment/api -n "$QUESTION_ID" --timeout=90s || true

echo "setup.sh: $QUESTION_ID ready"
