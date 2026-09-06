#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q108-47-networkpolicy-podselector-matchexpressions-notin${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: worker-pool
  labels:
    app: worker-pool
    tier: current
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 1
  selector:
    matchLabels:
      app: worker-pool
      tier: current
  template:
    metadata:
      labels:
        app: worker-pool
        tier: current
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: worker-pool
          image: busybox:1.36
          command: ["sh", "-c", "sleep 3600"]
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: worker-pool-legacy
  labels:
    app: worker-pool
    tier: legacy
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 1
  selector:
    matchLabels:
      app: worker-pool
      tier: legacy
  template:
    metadata:
      labels:
        app: worker-pool
        tier: legacy
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: worker-pool
          image: busybox:1.36
          command: ["sh", "-c", "sleep 3600"]
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: worker-pool-restrict-egress
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  podSelector:
    matchLabels:
      app: worker-pool
  policyTypes:
    - Egress
  egress:
    - to:
        - podSelector:
            matchLabels:
              tier: current
      ports:
        - protocol: TCP
          port: 8080
EOF

kubectl wait --for=condition=Available deployment/worker-pool -n "$QUESTION_ID" --timeout=90s || true
kubectl wait --for=condition=Available deployment/worker-pool-legacy -n "$QUESTION_ID" --timeout=90s || true

echo "setup.sh: $QUESTION_ID ready"
