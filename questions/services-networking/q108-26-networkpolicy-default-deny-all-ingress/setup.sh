#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q108-26-networkpolicy-default-deny-all-ingress${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: internal-svc
  labels:
    app: internal-svc
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 1
  selector:
    matchLabels:
      app: internal-svc
  template:
    metadata:
      labels:
        app: internal-svc
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: internal-svc
          image: httpd:2.4-alpine
          ports:
            - containerPort: 8080
          resources:
            requests:
              cpu: 25m
              memory: 32Mi
            limits:
              cpu: 50m
              memory: 64Mi
---
apiVersion: v1
kind: Service
metadata:
  name: internal-svc
  labels:
    app: internal-svc
    clusterdrill-question: $QUESTION_ID
spec:
  selector:
    app: internal-svc
  ports:
    - protocol: TCP
      port: 80
      targetPort: 8080
EOF

kubectl wait --for=condition=Available deployment/internal-svc -n "$QUESTION_ID" --timeout=90s || true

# probe-client: a plain client pod in the SAME namespace used to record (not
# assert) the precondition that internal-svc is reachable before any
# NetworkPolicy exists. It stays alive as a normal pod in the namespace so
# the candidate can optionally re-probe it after adding the policy; check.sh
# never asserts live traffic against it (this cluster's default CNI does not
# enforce NetworkPolicy objects - see check.sh for the same rationale used by
# every other NetworkPolicy question in this bank).
kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: probe-client
  labels:
    app: probe-client
    clusterdrill-question: $QUESTION_ID
spec:
  containers:
    - name: probe-client
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

kubectl wait --for=condition=Ready pod/probe-client -n "$QUESTION_ID" --timeout=90s || true

# Precondition check (recorded only, never asserted by check.sh): confirm
# probe-client can currently reach internal-svc before any NetworkPolicy
# exists in the namespace.
if kubectl exec -n "$QUESTION_ID" probe-client -- \
  wget -q -T 5 -O /dev/null "http://internal-svc.$QUESTION_ID.svc.cluster.local" 2>/dev/null; then
  echo "setup.sh: precondition confirmed - probe-client can currently reach internal-svc"
else
  echo "setup.sh: precondition check inconclusive (non-fatal) - continuing"
fi

echo "setup.sh: $QUESTION_ID ready"
