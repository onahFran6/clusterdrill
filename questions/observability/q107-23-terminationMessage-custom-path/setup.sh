#!/usr/bin/env bash
# Idempotent: creates/resets namespace q107-23-terminationmessage-custom-path
# and seeds a pod whose terminationMessagePath is mis-set so the container's
# failure message written to the default termination-log path is not
# captured by Kubernetes.
set -euo pipefail

QUESTION_ID="q107-23-terminationmessage-custom-path${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: batch-validator
  labels:
    app: batch-validator
    clusterdrill-question: $QUESTION_ID
spec:
  restartPolicy: Never
  containers:
    - name: batch-validator
      image: busybox:1.36
      command: ["sh", "-c", "echo \"validation failed: schema mismatch on field age\" > /dev/termination-log; exit 1"]
      terminationMessagePath: /tmp/nonexistent/term.log
EOF

kubectl wait --for=jsonpath='{.status.phase}'=Failed pod/batch-validator -n "$QUESTION_ID" --timeout=60s || true

echo "setup.sh: $QUESTION_ID ready"
