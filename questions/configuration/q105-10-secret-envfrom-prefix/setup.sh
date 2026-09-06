#!/usr/bin/env bash
# Idempotent: creates/resets namespace q105-10-secret-envfrom-prefix and
# seeds the Secret plus starting pod. Every cluster object created here
# carries the label clusterdrill-question=q105-10-secret-envfrom-prefix
#.

set -euo pipefail

QUESTION_ID="q105-10-secret-envfrom-prefix${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
kind: Secret
metadata:
  name: payment-creds
  labels:
    clusterdrill-question: $QUESTION_ID
stringData:
  API_KEY: pk_test_12345
  API_SECRET: sk_test_67890
---
apiVersion: v1
kind: Pod
metadata:
  name: payment-worker
  labels:
    app: payment-worker
    clusterdrill-question: $QUESTION_ID
spec:
  containers:
    - name: payment-worker
      image: nginx:1.25-alpine
EOF

kubectl wait --for=condition=Ready pod/payment-worker -n "$QUESTION_ID" --timeout=60s || true

echo "setup.sh: $QUESTION_ID ready"
