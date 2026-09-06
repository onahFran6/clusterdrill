#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q108-35-kubectl-expose-pod-imperative${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: cache-proxy
  labels:
    app: cache-proxy
    clusterdrill-question: $QUESTION_ID
spec:
  containers:
    - name: cache-proxy
      image: redis:7-alpine
      ports:
        - containerPort: 6379
EOF

kubectl wait --for=condition=Ready pod/cache-proxy -n "$QUESTION_ID" --timeout=90s || true

echo "setup.sh: $QUESTION_ID ready"
