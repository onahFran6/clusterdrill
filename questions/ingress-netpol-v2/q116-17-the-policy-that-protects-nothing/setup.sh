#!/usr/bin/env bash
# This question needs a second namespace (where the broken policy was
# mistakenly created). Per the established pattern for multi-namespace
# questions in this bank (see q108-28-diagnose-dns-wrong-namespace-suffix),
# WRONG_NS below is named as a suffix of $QUESTION_ID, carries no
# clusterdrill-question label (neither does the NetworkPolicy inside it),
# and is deleted/recreated wholesale on every run for its own idempotency.
set -euo pipefail

QUESTION_ID="q116-17-the-policy-that-protects-nothing${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
WRONG_NS="${QUESTION_ID}-wrong"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

kubectl delete namespace "$WRONG_NS" --ignore-not-found --wait=true >/dev/null 2>&1
kubectl create namespace "$WRONG_NS" \
  --dry-run=client -o yaml | kubectl apply -f -
apply_default_resource_limits "$WRONG_NS"
grant_user_namespace_access "$WRONG_NS" "${CLUSTERDRILL_USER_ID:-}"

kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: web
  labels:
    app: web
    clusterdrill-question: $QUESTION_ID
spec:
  containers:
    - name: web
      image: hashicorp/http-echo:1.0
      args: ["-listen=:5678", "-text=web"]
---
apiVersion: v1
kind: Service
metadata:
  name: web-svc
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  selector:
    app: web
  ports:
    - port: 80
      targetPort: 5678
---
apiVersion: v1
kind: Pod
metadata:
  name: frontend
  labels:
    app: frontend
    clusterdrill-question: $QUESTION_ID
spec:
  containers:
    - name: frontend
      image: busybox:1.36
      command: ["sleep", "3600"]
---
apiVersion: v1
kind: Pod
metadata:
  name: intruder
  labels:
    app: intruder
    clusterdrill-question: $QUESTION_ID
spec:
  containers:
    - name: intruder
      image: busybox:1.36
      command: ["sleep", "3600"]
EOF

# Fault: wrong namespace AND wrong podSelector case (app=Web, not app=web) -
# a policy that selects no pods at all is valid and silently does nothing.
kubectl apply -n "$WRONG_NS" -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: web-only-frontend
spec:
  podSelector:
    matchLabels:
      app: Web
  policyTypes: ["Ingress"]
  ingress:
    - from:
        - podSelector:
            matchLabels:
              app: frontend
EOF

kubectl wait --for=condition=Ready pod/web -n "$QUESTION_ID" --timeout=60s || true

echo "setup.sh: $QUESTION_ID ready (broken policy mistakenly in $WRONG_NS)"
