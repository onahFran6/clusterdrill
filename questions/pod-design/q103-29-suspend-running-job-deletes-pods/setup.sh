#!/usr/bin/env bash
# Idempotent: creates/resets namespace q103-29-suspend-running-job-deletes-pods
# and seeds a Job that is genuinely mid-execution (pod already Running) by
# the time this script returns - the whole point of this question is that
# the candidate must suspend a Job that is ALREADY running, not one that
# was created suspended.
set -euo pipefail

QUESTION_ID="q103-29-suspend-running-job-deletes-pods${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
JOB_NAME="report-builder"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

# suspend starts false (or unset - false is the default): the Job controller
# starts a pod for it right away, exactly like any normal Job.
#
# terminationGracePeriodSeconds is set low (5s) so that, once the candidate
# suspends this Job, the pod the controller deletes actually finishes
# terminating quickly - the container's own command (`sleep`) has no signal
# handler, so it dies on SIGTERM immediately, but keeping the grace period
# short bounds worst-case wall-clock time regardless.
kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: batch/v1
kind: Job
metadata:
  name: $JOB_NAME
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  suspend: false
  template:
    metadata:
      labels:
        clusterdrill-question: $QUESTION_ID
    spec:
      restartPolicy: Never
      terminationGracePeriodSeconds: 5
      containers:
        - name: report-builder
          image: busybox:1.36
          command: ["sleep", "600"]
          resources:
            requests:
              cpu: 25m
              memory: 32Mi
            limits:
              cpu: 50m
              memory: 64Mi
EOF

# Block until the Job's pod is genuinely Running before handing control
# back - the candidate (and check.sh's unsolved-state run) must find a
# real, already-running pod, not one still Pending/ContainerCreating.
kubectl wait pod -n "$QUESTION_ID" -l "job-name=$JOB_NAME" \
  --for=jsonpath='{.status.phase}'=Running --timeout=90s

echo "setup.sh: $QUESTION_ID ready (Job '$JOB_NAME' running)"
