#!/usr/bin/env bash
# This question needs a second namespace per §3 of this topic's build
# notes: the "outside" test namespace is its own extra namespace, never
# the shared `default` namespace (which would pollute it across every
# other concurrent session/question). Per the established multi-namespace
# pattern (see q108-28-diagnose-dns-wrong-namespace-suffix), OUTSIDE_NS
# below is named as a suffix of $QUESTION_ID, carries no
# clusterdrill-question label, and is deleted/recreated wholesale on every
# run for its own idempotency.
set -euo pipefail

QUESTION_ID="q116-13-lock-the-namespace-keep-it-working-inside${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
OUTSIDE_NS="${QUESTION_ID}-outside"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

kubectl delete namespace "$OUTSIDE_NS" --ignore-not-found --wait=true >/dev/null 2>&1
kubectl create namespace "$OUTSIDE_NS" \
  --dry-run=client -o yaml | kubectl apply -f -
apply_default_resource_limits "$OUTSIDE_NS"
grant_user_namespace_access "$OUTSIDE_NS" "${CLUSTERDRILL_USER_ID:-}"

kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: b
  labels:
    app: b
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 1
  selector:
    matchLabels:
      app: b
  template:
    metadata:
      labels:
        app: b
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: b
          image: hashicorp/http-echo:1.0
          args: ["-listen=:5678", "-text=b"]
          ports:
            - containerPort: 5678
---
apiVersion: v1
kind: Service
metadata:
  name: b-svc
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  selector:
    app: b
  ports:
    - port: 80
      targetPort: 5678
---
apiVersion: v1
kind: Pod
metadata:
  name: client
  labels:
    app: client
    clusterdrill-question: $QUESTION_ID
spec:
  containers:
    - name: client
      image: busybox:1.36
      command: ["sleep", "3600"]
EOF

kubectl apply -n "$OUTSIDE_NS" -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: outside
spec:
  replicas: 1
  selector:
    matchLabels:
      app: outside
  template:
    metadata:
      labels:
        app: outside
    spec:
      containers:
        - name: outside
          image: hashicorp/http-echo:1.0
          args: ["-listen=:5678", "-text=outside"]
          ports:
            - containerPort: 5678
---
apiVersion: v1
kind: Service
metadata:
  name: outside-svc
spec:
  selector:
    app: outside
  ports:
    - port: 80
      targetPort: 5678
EOF

kubectl wait --for=condition=Available deployment/b -n "$QUESTION_ID" --timeout=90s || true

echo "setup.sh: $QUESTION_ID ready (second namespace: $OUTSIDE_NS)"
