#!/usr/bin/env bash
# Idempotent: creates/resets namespace and seeds two Deployments plus two
# interacting NetworkPolicies, one of which has a deliberate podSelector
# label-value typo (tier: ap instead of tier: api).
set -euo pipefail

QUESTION_ID="q108-31-networkpolicy-label-selector-typo-cascading${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: cache-layer
  labels:
    tier: cache
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 1
  selector:
    matchLabels:
      tier: cache
  template:
    metadata:
      labels:
        tier: cache
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: cache-layer
          image: redis:7-alpine
          ports:
            - containerPort: 6379
          resources:
            requests:
              cpu: 25m
              memory: 32Mi
            limits:
              cpu: 50m
              memory: 64Mi
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-layer
  labels:
    tier: api
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 1
  selector:
    matchLabels:
      tier: api
  template:
    metadata:
      labels:
        tier: api
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: api-layer
          image: busybox:1.36
          command: ["sh", "-c", "sleep 3600"]
          resources:
            requests:
              cpu: 25m
              memory: 16Mi
            limits:
              cpu: 50m
              memory: 32Mi
EOF

# default-deny-cache-ingress: intentional baseline deny on cache-layer's
# pods. Must be left untouched by the candidate.
kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-cache-ingress
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  podSelector:
    matchLabels:
      tier: cache
  policyTypes:
    - Ingress
EOF

# allow-api-to-cache: meant to punch a hole in the baseline deny for
# api-layer's real "tier: api" label, but the from-selector's value is
# typoed as "ap" - because NetworkPolicies selecting the same pods are
# additive, this typo means this policy's ingress rule never matches any
# real pod, so default-deny-cache-ingress's empty ingress list remains the
# only rule in effect and all traffic (including from api-layer) is denied.
kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-api-to-cache
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  podSelector:
    matchLabels:
      tier: cache
  policyTypes:
    - Ingress
  ingress:
    - from:
        - podSelector:
            matchLabels:
              tier: ap
      ports:
        - protocol: TCP
          port: 6379
EOF

kubectl wait --for=condition=Available deployment/cache-layer -n "$QUESTION_ID" --timeout=90s || true
kubectl wait --for=condition=Available deployment/api-layer -n "$QUESTION_ID" --timeout=90s || true

echo "setup.sh: $QUESTION_ID ready"
