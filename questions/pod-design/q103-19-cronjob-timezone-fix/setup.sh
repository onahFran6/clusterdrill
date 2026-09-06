#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q103-19-cronjob-timezone-fix${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

# Schedule "0 9 * * *" was written assuming America/New_York local time, but
# .spec.timeZone is left unset - Kubernetes falls back to UTC, so this fires
# at 9am UTC instead of 9am Eastern. The candidate must add .spec.timeZone
# without touching the schedule fields.
kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: batch/v1
kind: CronJob
metadata:
  name: morning-standup-reminder
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  schedule: "0 9 * * *"
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
            - name: morning-standup-reminder
              image: busybox:1.36
              command: ["echo", "standup in 15 minutes"]
              resources:
                requests:
                  cpu: 25m
                  memory: 32Mi
                limits:
                  cpu: 50m
                  memory: 64Mi
EOF

echo "setup.sh: $QUESTION_ID ready"
