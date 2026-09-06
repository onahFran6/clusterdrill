#!/usr/bin/env bash
# Idempotent: creates/resets namespace q103-24-job-podfailurepolicy-ignore-exit-code and seeds
# two broken Jobs. Every object created here carries the label
# clusterdrill-question=q103-24-job-podfailurepolicy-ignore-exit-code.

set -euo pipefail

QUESTION_ID="q103-24-job-podfailurepolicy-ignore-exit-code${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

# code42-loader: always exits 42 ("nothing to load" - not a real failure), but
# has NO podFailurePolicy yet, so today it retries this exit like any other
# failure instead of failing the Job fast. backoffLimit is deliberately left
# high enough that, uncorrected, this wastes multiple retry pods before
# check.sh's bounded observation window would ever see it reach Failed.
kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: batch/v1
kind: Job
metadata:
  name: code42-loader
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  backoffLimit: 4
  template:
    metadata:
      labels:
        clusterdrill-question: $QUESTION_ID
    spec:
      restartPolicy: Never
      containers:
        - name: loader
          image: busybox:1.36
          command: ["sh", "-c", "exit 42"]
          resources:
            requests:
              cpu: 25m
              memory: 32Mi
            limits:
              cpu: 50m
              memory: 64Mi
EOF

# flaky-loader: always exits 7 (a stand-in transient error code - never 42).
# It already HAS a podFailurePolicy, but the rule is wrong: it matches any
# nonzero exit code (operator NotIn, values [0]) and FailJobs on the very
# first failure, instead of letting backoffLimit's normal retry behavior run.
kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: batch/v1
kind: Job
metadata:
  name: flaky-loader
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  backoffLimit: 2
  podFailurePolicy:
    rules:
      - action: FailJob
        onExitCodes:
          containerName: loader
          operator: NotIn
          values: [0]
  template:
    metadata:
      labels:
        clusterdrill-question: $QUESTION_ID
    spec:
      restartPolicy: Never
      containers:
        - name: loader
          image: busybox:1.36
          command: ["sh", "-c", "exit 7"]
          resources:
            requests:
              cpu: 25m
              memory: 32Mi
            limits:
              cpu: 50m
              memory: 64Mi
EOF

echo "setup.sh: $QUESTION_ID ready"
