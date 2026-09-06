#!/usr/bin/env bash
# Idempotent: creates/resets namespace q107-01-liveness-httpget-basic and
# seeds a running pod with no liveness probe.
set -euo pipefail

QUESTION_ID="q107-01-liveness-httpget-basic${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
kind: Pod
metadata:
  name: web-front
  labels:
    app: web-front
    clusterdrill-question: $QUESTION_ID
spec:
  containers:
    - name: web-front
      image: nginx:1.25-alpine
      ports:
        - containerPort: 80
EOF

kubectl wait --for=condition=Ready pod/web-front -n "$QUESTION_ID" --timeout=60s || true

echo "setup.sh: $QUESTION_ID ready"
