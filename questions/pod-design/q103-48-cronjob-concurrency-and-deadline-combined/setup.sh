#!/usr/bin/env bash
# Idempotent: creates/resets namespace
# q103-48-cronjob-concurrency-and-deadline-combined and seeds a CronJob missing all
# three required fields (concurrencyPolicy, startingDeadlineSeconds, jobTemplate.spec.backoffLimit).
# check.sh only asserts the field values (matching the existing q103-08 Forbid question's own
# precedent) rather than waiting on real overlapping/missed schedule ticks, which would make
# grading slow and timing-flaky.

set -euo pipefail

QUESTION_ID="q103-48-cronjob-concurrency-and-deadline-combined${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: ledger-close
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  schedule: "* * * * *"
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
          restartPolicy: Never
          containers:
            - name: ledger-close
              image: busybox:1.36
              command: ["sh", "-c", "sleep 90"]
              resources:
                requests:
                  cpu: 25m
                  memory: 32Mi
                limits:
                  cpu: 50m
                  memory: 64Mi
EOF

echo "setup.sh: $QUESTION_ID ready"
