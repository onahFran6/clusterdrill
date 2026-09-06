#!/usr/bin/env bash
# Idempotent: creates/resets namespace and applies a Job that always fails,
# with backoffLimit low enough that it exhausts retries and reaches a
# terminal Failed state, leaving multiple failed Pods behind for the
# candidate to investigate. This apply itself succeeds; it's the Job's own
# pods that fail - don't let that abort setup.sh.

set -uo pipefail

QUESTION_ID="q107-41-job-failed-pod-logs-forensics${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f - || {
  echo "setup.sh: failed to create/apply namespace $QUESTION_ID" >&2
  exit 1
}
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: batch/v1
kind: Job
metadata:
  name: data-migration
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  backoffLimit: 1
  template:
    metadata:
      labels:
        clusterdrill-question: $QUESTION_ID
    spec:
      restartPolicy: Never
      containers:
        - name: data-migration
          image: busybox:1.36
          command: ["sh", "-c", "echo 'FATAL: missing required env var DB_HOST' >&2; exit 1"]
EOF

kubectl wait --for=condition=Failed job/data-migration -n "$QUESTION_ID" --timeout=60s || true

echo "setup.sh: $QUESTION_ID ready (Job 'data-migration' has failed, leaving failed Pods to investigate)"
