#!/usr/bin/env bash
# Idempotent: creates/resets namespace and seeds a CronJob that is broken in
# two independent ways at once - spec.suspend=true AND an invalid, never-
# firing schedule (Feb 31st doesn't exist) - so the candidate must notice
# and fix both.
set -euo pipefail

QUESTION_ID="q101-28-fix-cronjob-suspended-and-wrong-schedule${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
kind: CronJob
metadata:
  name: log-rotator
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  schedule: "0 0 31 2 *"
  suspend: true
  jobTemplate:
    metadata:
      labels:
        clusterdrill-question: $QUESTION_ID
    spec:
      template:
        metadata:
          labels:
            clusterdrill-question: $QUESTION_ID
        spec:
          restartPolicy: OnFailure
          containers:
            - name: log-rotator
              image: busybox:1.36
              command: ["sh", "-c", "echo rotate"]
EOF

echo "setup.sh: $QUESTION_ID ready"
