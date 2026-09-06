#!/usr/bin/env bash
# Idempotent: creates/resets the namespace and seeds a target Deployment
# plus a NetworkPolicy whose ingress `from` list has podSelector and
# namespaceSelector as two SEPARATE list entries (OR semantics) instead of
# two fields on one entry (AND semantics) - the bug the candidate must fix.
set -euo pipefail

QUESTION_ID="q108-32-networkpolicy-and-vs-or-selector-semantics${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: payment-api
  labels:
    app: payment-api
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 1
  selector:
    matchLabels:
      app: payment-api
  template:
    metadata:
      labels:
        app: payment-api
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: payment-api
          image: httpd:2.4-alpine
          ports:
            - containerPort: 8443
          resources:
            requests:
              cpu: 25m
              memory: 32Mi
            limits:
              cpu: 50m
              memory: 64Mi
EOF

# allow-trusted-platform-clients: intended to require BOTH role=trusted-client
# AND a namespace labeled team=platform, but the podSelector and
# namespaceSelector are written as two SEPARATE entries in the `from` list -
# which Kubernetes evaluates as OR (the union of each entry's matches), not
# AND. This over-permissive policy is the bug the candidate must fix by
# merging both selectors into a single `from` entry.
kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-trusted-platform-clients
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  podSelector:
    matchLabels:
      app: payment-api
  policyTypes:
    - Ingress
  ingress:
    - from:
        - podSelector:
            matchLabels:
              role: trusted-client
        - namespaceSelector:
            matchLabels:
              team: platform
      ports:
        - protocol: TCP
          port: 8443
EOF

kubectl wait --for=condition=Available deployment/payment-api -n "$QUESTION_ID" --timeout=90s || true

echo "setup.sh: $QUESTION_ID ready"
