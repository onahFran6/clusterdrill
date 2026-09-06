#!/usr/bin/env bash
# Idempotent: creates/resets namespace q105-23-optional-configmap-key-env and
# seeds the ConfigMap plus a pod whose container fails to start because it
# references a required (non-optional) ConfigMap key that doesn't exist.
# Every cluster object created here carries the label
# clusterdrill-question=q105-23-optional-configmap-key-env
#.

set -euo pipefail

QUESTION_ID="q105-23-optional-configmap-key-env${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: app-flags
  labels:
    clusterdrill-question: $QUESTION_ID
data:
  FEATURE_X: "on"
---
apiVersion: v1
kind: Pod
metadata:
  name: flagreader
  labels:
    app: flagreader
    clusterdrill-question: $QUESTION_ID
spec:
  containers:
    - name: flagreader
      image: nginx:1.25-alpine
      env:
        - name: FEATURE_X
          valueFrom:
            configMapKeyRef:
              name: app-flags
              key: FEATURE_X
        - name: FEATURE_Y
          valueFrom:
            configMapKeyRef:
              name: app-flags
              key: FEATURE_Y
EOF

kubectl wait --for=condition=Ready pod/flagreader -n "$QUESTION_ID" --timeout=30s || true

echo "setup.sh: $QUESTION_ID ready"
