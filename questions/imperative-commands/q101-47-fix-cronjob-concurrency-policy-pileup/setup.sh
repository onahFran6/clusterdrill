#!/usr/bin/env bash
# Idempotent: creates/resets namespace
# q101-47-fix-cronjob-concurrency-policy-pileup and seeds a CronJob that
# fires every minute (schedule "* * * * *") with concurrencyPolicy: Allow
# and a Job that runs for 75s - longer than the schedule interval, so
# consecutive runs overlap/pile up until the candidate switches the policy
# to Forbid.

set -euo pipefail

QUESTION_ID="q101-47-fix-cronjob-concurrency-policy-pileup${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: log-compactor
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  schedule: "* * * * *"
  concurrencyPolicy: Allow
  successfulJobsHistoryLimit: 3
  failedJobsHistoryLimit: 1
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
            - name: log-compactor
              image: busybox:1.36
              command: ["sh", "-c", "sleep 75 && echo compacted"]
              resources:
                requests:
                  cpu: 25m
                  memory: 32Mi
                limits:
                  cpu: 50m
                  memory: 64Mi
EOF

echo "setup.sh: $QUESTION_ID ready"
