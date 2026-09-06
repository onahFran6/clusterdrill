#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q103-18-cronjob-fix-job-template${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: data-sync
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
          restartPolicy: OnFailure
          containers:
            - name: data-sync
              image: busybox:this-tag-does-not-exist
              command: ["echo", "syncing"]
EOF

echo "setup.sh: $QUESTION_ID ready"
