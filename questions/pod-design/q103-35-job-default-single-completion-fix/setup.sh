#!/usr/bin/env bash
# Idempotent: creates/resets namespace q103-35-job-default-single-completion-fix and seeds a Job
# with completions:5 (wrong - it should run exactly once). completions is immutable, so the
# candidate must delete and recreate it, matching the q103-24/q103-25 precedent for immutable
# Job-spec fields.

set -euo pipefail

QUESTION_ID="q103-35-job-default-single-completion-fix${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: onetime-cleanup
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  completions: 5
  parallelism: 1
  template:
    metadata:
      labels:
        clusterdrill-question: $QUESTION_ID
    spec:
      restartPolicy: Never
      containers:
        - name: onetime-cleanup
          image: busybox:1.36
          command: ["echo", "cleaning"]
          resources:
            requests:
              cpu: 25m
              memory: 32Mi
            limits:
              cpu: 50m
              memory: 64Mi
EOF

echo "setup.sh: $QUESTION_ID ready"
