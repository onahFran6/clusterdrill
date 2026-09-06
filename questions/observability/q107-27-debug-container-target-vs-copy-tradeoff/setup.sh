#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q107-27-debug-container-target-vs-copy-tradeoff${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: worker-proc
  labels:
    app: worker-proc
    clusterdrill-question: $QUESTION_ID
spec:
  containers:
    - name: worker-proc
      image: busybox:1.36
      command: ["sh", "-c", "while true; do sleep 2 & wait; done"]
EOF

kubectl wait --for=condition=Ready pod/worker-proc -n "$QUESTION_ID" --timeout=60s || true

echo "setup.sh: $QUESTION_ID ready"
