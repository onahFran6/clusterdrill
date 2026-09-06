#!/usr/bin/env bash
# Idempotent: creates/resets namespace q103-43-job-parallelism-scale-up-live and seeds a Job with
# completions:6, parallelism:1. Each pod sleeps briefly before succeeding, so the unpatched Job
# takes noticeably longer to finish than a parallelism:3 run would - the candidate raises
# parallelism in place (a mutable field, unlike completions) rather than deleting/recreating.

set -euo pipefail

QUESTION_ID="q103-43-job-parallelism-scale-up-live${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: speedy-batch
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  completions: 6
  parallelism: 1
  template:
    metadata:
      labels:
        clusterdrill-question: $QUESTION_ID
    spec:
      restartPolicy: Never
      containers:
        - name: speedy-batch
          image: busybox:1.36
          command: ["sh", "-c", "sleep 3; exit 0"]
          resources:
            requests:
              cpu: 25m
              memory: 32Mi
            limits:
              cpu: 50m
              memory: 64Mi
EOF

echo "setup.sh: $QUESTION_ID ready"
