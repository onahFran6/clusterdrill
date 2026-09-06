#!/usr/bin/env bash
# Idempotent: creates/resets namespace and seeds a pod whose container exits
# immediately (no long-running command), guaranteeing CrashLoopBackOff.
set -euo pipefail

QUESTION_ID="q107-07-diagnose-crashloop-badcommand${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: batch-worker
  labels:
    app: batch-worker
    clusterdrill-question: $QUESTION_ID
spec:
  containers:
    - name: batch-worker
      image: busybox:1.36
      command: ["sh", "-c", "echo starting; exit 1"]
EOF

echo "setup.sh: $QUESTION_ID ready (pod will enter CrashLoopBackOff)"
