#!/usr/bin/env bash
# The broken manifest is written to a file, never `kubectl apply`-d here: a
# NetworkPolicyPeer combining ipBlock with podSelector/namespaceSelector is
# rejected by the API server at admission time ("may not specify both
# ipBlock and another peer"), so "seeding" it live is impossible - the
# candidate's task is to fix the file and apply it themselves (same pattern
# as q107-34's deprecated-apiVersion file-based fix).
set -euo pipefail

QUESTION_ID="q108-50-networkpolicy-ipblock-peer-exclusivity-fix${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: partner-gateway
  labels:
    app: partner-gateway
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 1
  selector:
    matchLabels:
      app: partner-gateway
  template:
    metadata:
      labels:
        app: partner-gateway
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: partner-gateway
          image: httpd:2.4-alpine
          ports:
            - containerPort: 443
EOF

WORK_DIR="$(question_workdir "$QUESTION_ID")"

cat >"$WORK_DIR/netpol.yaml" <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: partner-gateway-allow-ingress
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  podSelector:
    matchLabels:
      app: partner-gateway
  policyTypes:
    - Ingress
  ingress:
    - from:
        - podSelector:
            matchLabels:
              role: internal-caller
          ipBlock:
            cidr: 203.0.113.0/24
          namespaceSelector:
            matchLabels:
              team: observability
      ports:
        - protocol: TCP
          port: 443
EOF

kubectl wait --for=condition=Available deployment/partner-gateway -n "$QUESTION_ID" --timeout=90s || true

echo "setup.sh: $QUESTION_ID ready (broken manifest at $WORK_DIR/netpol.yaml, not yet applied)"
