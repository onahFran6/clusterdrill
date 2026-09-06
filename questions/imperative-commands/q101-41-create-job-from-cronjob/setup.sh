#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q101-41-create-job-from-cronjob${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: nightly-report
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  schedule: "0 2 * * *"
  suspend: true
  jobTemplate:
    spec:
      template:
        metadata:
          labels:
            clusterdrill-question: $QUESTION_ID
        spec:
          containers:
            - name: nightly-report
              image: busybox:1.36
              command: ["sh", "-c", "echo generating-report"]
              resources:
                requests:
                  cpu: 25m
                  memory: 32Mi
                limits:
                  cpu: 50m
                  memory: 64Mi
          restartPolicy: OnFailure
EOF

echo "setup.sh: $QUESTION_ID ready"
