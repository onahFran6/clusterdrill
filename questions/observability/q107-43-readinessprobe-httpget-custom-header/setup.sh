#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q107-43-readinessprobe-httpget-custom-header${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

# readinessProbe has no custom header - the platform's health-check
# convention (stated in QUESTION.md) requires one, so the candidate must
# add it without changing path/port.
kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: api-gateway
  labels:
    app: api-gateway
    clusterdrill-question: $QUESTION_ID
spec:
  containers:
    - name: api-gateway
      image: nginx:1.25-alpine
      readinessProbe:
        httpGet:
          path: /
          port: 80
        periodSeconds: 2
EOF

kubectl wait --for=condition=Ready pod/api-gateway -n "$QUESTION_ID" --timeout=60s || true

echo "setup.sh: $QUESTION_ID ready"
