#!/usr/bin/env bash
# Idempotent: creates/resets namespace q101-23-diagnose-wrong-configmap-key-reference
# and seeds a ConfigMap plus a broken Pod whose extra configMapKeyRef env var
# points at a nonexistent key, so the container sits in
# CreateContainerConfigError until the candidate fixes the key reference.
# Every cluster object created here carries the label
# clusterdrill-question=q101-23-diagnose-wrong-configmap-key-reference
#.

set -euo pipefail

QUESTION_ID="q101-23-diagnose-wrong-configmap-key-reference${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: app-settings
  labels:
    clusterdrill-question: $QUESTION_ID
data:
  LOG_LEVEL: "info"
  MAX_CONNECTIONS: "100"
---
apiVersion: v1
kind: Pod
metadata:
  name: settings-reader
  labels:
    app: settings-reader
    clusterdrill-question: $QUESTION_ID
spec:
  containers:
    - name: settings-reader
      image: nginx:1.25-alpine
      envFrom:
        - configMapRef:
            name: app-settings
      env:
        - name: MAX_CONN
          valueFrom:
            configMapKeyRef:
              name: app-settings
              key: MAX_CONN
EOF

# Give the kubelet a moment to attempt (and fail) the container create so
# describe/events already show CreateContainerConfigError for the candidate
# to diagnose, but don't hang setup.sh waiting on a pod that will never
# become Ready on its own.
kubectl wait --for=condition=Ready pod/settings-reader -n "$QUESTION_ID" --timeout=20s || true

echo "setup.sh: $QUESTION_ID ready"
