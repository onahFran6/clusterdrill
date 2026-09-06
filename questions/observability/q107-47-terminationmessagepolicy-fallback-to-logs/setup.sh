#!/usr/bin/env bash
# Idempotent: creates/resets namespace and applies a Pod whose container
# always fails and prints a specific reason to stderr - but the default
# terminationMessagePolicy (File) only reads /dev/termination-log, which
# this container never writes to, so kubectl's termination message stays
# empty even though a perfectly good failure reason is sitting right there
# in the container's own log output.

set -euo pipefail

QUESTION_ID="q107-47-terminationmessagepolicy-fallback-to-logs${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: batch-runner
  labels:
    app: batch-runner
    clusterdrill-question: $QUESTION_ID
spec:
  containers:
    - name: batch-runner
      image: busybox:1.36
      command: ["sh", "-c", "echo custom failure: disk quota exceeded >&2; exit 1"]
EOF

sleep 15

echo "setup.sh: $QUESTION_ID ready (batch-runner keeps failing, but its termination message is empty)"
