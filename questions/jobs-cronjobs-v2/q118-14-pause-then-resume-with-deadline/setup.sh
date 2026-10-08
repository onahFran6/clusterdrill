#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q118-14-pause-then-resume-with-deadline${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

NS="$QUESTION_ID"
kubectl create namespace "$NS" --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$NS" "clusterdrill-question=$NS" --overwrite
apply_default_resource_limits "$NS"
grant_user_namespace_access "$NS" "${CLUSTERDRILL_USER_ID:-}"
kubectl apply -n "$NS" -f - <<YAML
apiVersion: batch/v1
kind: CronJob
metadata:
  name: billing
  namespace: $NS
  labels:
    clusterdrill-question: $NS
spec:
  schedule: '*/1 * * * *'
  jobTemplate:
    spec:
      template:
        spec:
          restartPolicy: Never
          containers:
          - name: billing
            image: busybox:1.36
            command:
            - echo
            - billed
YAML

echo "setup.sh: $QUESTION_ID ready"
