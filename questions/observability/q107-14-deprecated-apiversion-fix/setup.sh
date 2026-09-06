#!/usr/bin/env bash
# Idempotent: creates/resets namespace and writes a broken manifest (removed
# apiVersion) to this question's terminal working directory for the
# candidate to fix and apply. The manifest itself is never applied here -
# batch/v1beta1 CronJob no longer exists as a registered kind on this
# cluster, so kubectl apply would simply fail; the seeded artifact is the
# file on disk, not a live object.
set -euo pipefail

QUESTION_ID="q107-14-deprecated-apiversion-fix${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

WORK_DIR="$(question_workdir "$QUESTION_ID")"
cat > "$WORK_DIR/q107-14-cronjob.yaml" <<EOF
apiVersion: batch/v1beta1
kind: CronJob
metadata:
  name: nightly-cleanup
  namespace: $QUESTION_ID
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  schedule: "0 2 * * *"
  jobTemplate:
    spec:
      template:
        metadata:
          labels:
            clusterdrill-question: $QUESTION_ID
        spec:
          containers:
            - name: nightly-cleanup
              image: busybox:1.36
              command: ["sh", "-c", "echo cleanup ran"]
          restartPolicy: OnFailure
EOF

echo "setup.sh: $QUESTION_ID ready (broken manifest at $WORK_DIR/q107-14-cronjob.yaml)"
