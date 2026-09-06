#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q103-03-job-backofflimit-retries${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: flaky-task
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  backoffLimit: 50
  template:
    metadata:
      labels:
        clusterdrill-question: $QUESTION_ID
    spec:
      restartPolicy: Never
      containers:
        - name: flaky-task
          image: busybox:1.36
          command: ["sh", "-c", "exit 1"]
EOF

echo "setup.sh: $QUESTION_ID ready"
