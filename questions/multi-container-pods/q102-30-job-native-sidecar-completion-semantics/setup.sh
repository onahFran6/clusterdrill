#!/usr/bin/env bash
# Idempotent: creates/resets namespace q102-30-job-native-sidecar-completion-semantics
# and seeds a Job whose "sidecar" is mistakenly a regular container instead
# of a native sidecar (initContainer with restartPolicy: Always) - so the
# long-running log-shipper container blocks the Pod, and therefore the Job,
# from ever reaching Succeeded/Complete.
set -euo pipefail

QUESTION_ID="q102-30-job-native-sidecar-completion-semantics${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

# Reset path: a previous solve may have left the Job in a Complete state
# (or mid-flight), so delete it before reseeding the broken version - Job
# pod templates are immutable, and re-applying the broken spec over a
# fixed one would otherwise be rejected outright.
kubectl delete job log-shipping-job -n "$QUESTION_ID" --ignore-not-found --wait=true >/dev/null 2>&1

kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: batch/v1
kind: Job
metadata:
  name: log-shipping-job
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  backoffLimit: 0
  template:
    metadata:
      labels:
        clusterdrill-question: $QUESTION_ID
    spec:
      restartPolicy: Never
      containers:
        - name: digest
          image: busybox:1.36
          command: ["sh", "-c", "echo processing batch; sleep 5; exit 0"]
          resources:
            requests:
              cpu: 25m
              memory: 32Mi
            limits:
              cpu: 50m
              memory: 64Mi
        # BUG: this is meant to be a native sidecar (initContainers entry
        # with restartPolicy: Always) but was added here as a plain second
        # container instead, so it runs forever and the Pod can never reach
        # Succeeded.
        - name: log-shipper
          image: busybox:1.36
          command: ["sh", "-c", "while true; do echo shipping logs; sleep 5; done"]
          resources:
            requests:
              cpu: 25m
              memory: 32Mi
            limits:
              cpu: 50m
              memory: 64Mi
EOF

echo "setup.sh: $QUESTION_ID ready"
