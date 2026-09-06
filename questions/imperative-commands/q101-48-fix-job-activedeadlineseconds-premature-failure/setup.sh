#!/usr/bin/env bash
# Idempotent: creates/resets namespace
# q101-48-fix-job-activedeadlineseconds-premature-failure and seeds a Job
# whose activeDeadlineSeconds (5) is far shorter than how long its container
# actually needs to run (sleep 20), so the Job controller kills it and marks
# it Failed/DeadlineExceeded every time, deterministically and quickly.

set -euo pipefail

QUESTION_ID="q101-48-fix-job-activedeadlineseconds-premature-failure${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: batch/v1
kind: Job
metadata:
  name: batch-migrate
  labels:
    app: batch-migrate
    clusterdrill-question: $QUESTION_ID
spec:
  activeDeadlineSeconds: 5
  backoffLimit: 2
  template:
    metadata:
      labels:
        app: batch-migrate
        clusterdrill-question: $QUESTION_ID
    spec:
      restartPolicy: Never
      containers:
        - name: batch-migrate
          image: busybox:1.36
          command: ["sh", "-c", "sleep 20 && echo migrated"]
          resources:
            requests:
              cpu: 25m
              memory: 32Mi
            limits:
              cpu: 50m
              memory: 64Mi
EOF

kubectl wait --for=condition=Failed job/batch-migrate -n "$QUESTION_ID" --timeout=30s || true

echo "setup.sh: $QUESTION_ID ready"
