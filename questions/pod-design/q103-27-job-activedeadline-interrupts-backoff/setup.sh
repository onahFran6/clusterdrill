#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q103-27-job-activedeadline-interrupts-backoff${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

# The container always fails after a short sleep. backoffLimit=6 means it
# would naturally retry for several minutes before giving up on its own
# (Job backoff grows 10s, 20s, 40s, ... between attempts). activeDeadlineSeconds
# is deliberately set far too generous (90s) here - generous enough that it
# never actually interrupts anything within the time this question is graded
# on, so the Job would eventually fail with BackoffLimitExceeded instead of
# the deadline doing its intended job. The candidate must lower it.
kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: batch/v1
kind: Job
metadata:
  name: stubborn-retrier
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  backoffLimit: 6
  activeDeadlineSeconds: 90
  template:
    metadata:
      labels:
        clusterdrill-question: $QUESTION_ID
    spec:
      restartPolicy: Never
      containers:
        - name: stubborn-retrier
          image: busybox:1.36
          command: ["sh", "-c", "sleep 5; exit 1"]
          resources:
            requests:
              cpu: 25m
              memory: 32Mi
            limits:
              cpu: 50m
              memory: 64Mi
EOF

echo "setup.sh: $QUESTION_ID ready"
