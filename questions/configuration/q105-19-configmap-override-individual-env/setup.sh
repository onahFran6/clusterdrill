#!/usr/bin/env bash
# Idempotent: creates/resets namespace
# q105-19-configmap-override-individual-env and seeds the ConfigMap plus a
# pod that already bulk-imports it via envFrom. Every cluster object
# created here carries the label
# clusterdrill-question=q105-19-configmap-override-individual-env
#.

set -euo pipefail

QUESTION_ID="q105-19-configmap-override-individual-env${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: service-defaults
  labels:
    clusterdrill-question: $QUESTION_ID
data:
  TIMEOUT_SECONDS: "30"
  RETRY_COUNT: "3"
---
apiVersion: v1
kind: Pod
metadata:
  name: notifier
  labels:
    app: notifier
    clusterdrill-question: $QUESTION_ID
spec:
  containers:
    - name: notifier
      image: nginx:1.25-alpine
      envFrom:
        - configMapRef:
            name: service-defaults
EOF

kubectl wait --for=condition=Ready pod/notifier -n "$QUESTION_ID" --timeout=60s || true

echo "setup.sh: $QUESTION_ID ready"
