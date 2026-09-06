#!/usr/bin/env bash
# Idempotent: creates/resets namespace q103-33-job-invalid-restartpolicy-fix and writes a Job
# manifest with an API-rejected restartPolicy to this question's terminal working directory. The
# manifest is deliberately never applied here - kubectl apply on the manifest as-written fails
# validation entirely, so there is no live object to seed and the unsolved state has NO Job at all
# (this keeps the unsolved score genuinely 0, matching the q103-23 nodeName precedent for
# "unapplied manifest" questions).

set -euo pipefail

QUESTION_ID="q103-33-job-invalid-restartpolicy-fix${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

WORK_DIR="$(question_workdir "$QUESTION_ID")"
cat > "$WORK_DIR/broken-once.yaml" <<EOF
# REJECTED by the API server - a Job's pod template cannot use
# restartPolicy: Always:
#   error: Job.batch "broken-once" is invalid: spec.template.spec.restartPolicy:
#   Unsupported value: "Always": supported values: "OnFailure", "Never"
apiVersion: batch/v1
kind: Job
metadata:
  name: broken-once
  namespace: $QUESTION_ID
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  template:
    metadata:
      labels:
        clusterdrill-question: $QUESTION_ID
    spec:
      restartPolicy: Always
      containers:
        - name: broken-once
          image: busybox:1.36
          command: ["echo", "done"]
          resources:
            requests:
              cpu: 25m
              memory: 32Mi
            limits:
              cpu: 50m
              memory: 64Mi
EOF

echo "setup.sh: $QUESTION_ID ready (invalid manifest at $WORK_DIR/broken-once.yaml, not yet applied)"
