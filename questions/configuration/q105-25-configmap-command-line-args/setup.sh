#!/usr/bin/env bash
# Idempotent: creates/resets namespace q105-25-configmap-command-line-args and
# seeds the ConfigMap plus a starting pod that never references it. Every
# cluster object created here carries the label
# clusterdrill-question=q105-25-configmap-command-line-args
#.

set -euo pipefail

QUESTION_ID="q105-25-configmap-command-line-args${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: greeter-config
  labels:
    clusterdrill-question: $QUESTION_ID
data:
  GREETING: "Hello"
  TARGET: "World"
---
apiVersion: v1
kind: Pod
metadata:
  name: greeter
  labels:
    app: greeter
    clusterdrill-question: $QUESTION_ID
spec:
  containers:
    - name: greeter
      image: busybox:1.36
      command: ["sleep", "3600"]
EOF

kubectl wait --for=condition=Ready pod/greeter -n "$QUESTION_ID" --timeout=60s || true

echo "setup.sh: $QUESTION_ID ready"
