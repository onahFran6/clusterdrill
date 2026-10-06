#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q111-05-rollout-restart-stale-env${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: web-config
  labels:
    clusterdrill-question: $QUESTION_ID
data:
  GREETING: hello
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: greeter
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 3
  selector:
    matchLabels:
      app: greeter
  template:
    metadata:
      labels:
        app: greeter
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: nginx
          image: nginx:1.27
          envFrom:
            - configMapRef:
                name: web-config
EOF

kubectl rollout status deployment/greeter -n "$QUESTION_ID" --timeout=60s || true

# The pods above already read GREETING=hello at container start. Changing
# the ConfigMap now (after the pods exist) reproduces the exact "config
# changed, pods didn't" staleness the task describes - a ConfigMap edit is
# not a pod template change, so no rollout happens on its own.
kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: web-config
  labels:
    clusterdrill-question: $QUESTION_ID
data:
  GREETING: hola
EOF

echo "setup.sh: $QUESTION_ID ready"
