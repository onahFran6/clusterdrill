#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q106-39-allowprivilegeescalation-false${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

# Deliberately missing allowPrivilegeEscalation - defaults to true, which
# the candidate must lock down without changing anything else.
kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: web-worker
  labels:
    app: web-worker
    clusterdrill-question: $QUESTION_ID
spec:
  containers:
    - name: web-worker
      image: nginx:1.25-alpine
EOF

kubectl wait --for=condition=Ready pod/web-worker -n "$QUESTION_ID" --timeout=60s || true

echo "setup.sh: $QUESTION_ID ready (web-worker running with allowPrivilegeEscalation unset)"
