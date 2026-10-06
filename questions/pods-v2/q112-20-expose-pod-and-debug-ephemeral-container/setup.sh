#!/usr/bin/env bash
# Idempotent: creates/resets the namespace and seeds the bare Pod the
# candidate must expose and debug. The Service and ephemeral container
# are NOT seeded - building/attaching them is the exercise.
set -euo pipefail

QUESTION_ID="q112-20-expose-pod-and-debug-ephemeral-container${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: api
  labels:
    app: api
    clusterdrill-question: $QUESTION_ID
spec:
  containers:
    - name: web
      image: nginx:1.27-alpine
      ports:
        - name: http
          containerPort: 80
EOF

echo "setup.sh: $QUESTION_ID ready"
