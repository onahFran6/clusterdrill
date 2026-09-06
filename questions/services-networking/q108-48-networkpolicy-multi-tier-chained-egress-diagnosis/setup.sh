#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q108-48-networkpolicy-multi-tier-chained-egress-diagnosis${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

for tier in frontend backend database; do
  kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: $tier
  labels:
    tier: $tier
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 1
  selector:
    matchLabels:
      tier: $tier
  template:
    metadata:
      labels:
        tier: $tier
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: $tier
          image: busybox:1.36
          command: ["sh", "-c", "sleep 3600"]
EOF
done

kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: frontend-to-backend-egress
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  podSelector:
    matchLabels:
      tier: frontend
  policyTypes:
    - Egress
  egress:
    - to:
        - podSelector:
            matchLabels:
              tier: backend
      ports:
        - protocol: TCP
          port: 8080
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: backend-to-database-egress
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  podSelector:
    matchLabels:
      tier: backend
  policyTypes:
    - Egress
  egress:
    - to:
        - podSelector:
            matchLabels:
              tier: databse
      ports:
        - protocol: TCP
          port: 5432
EOF

kubectl wait --for=condition=Available deployment/frontend -n "$QUESTION_ID" --timeout=90s || true
kubectl wait --for=condition=Available deployment/backend -n "$QUESTION_ID" --timeout=90s || true
kubectl wait --for=condition=Available deployment/database -n "$QUESTION_ID" --timeout=90s || true

echo "setup.sh: $QUESTION_ID ready"
