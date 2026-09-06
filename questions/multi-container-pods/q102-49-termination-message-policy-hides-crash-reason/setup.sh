#!/usr/bin/env bash
# Idempotent: creates/resets namespace q102-49-termination-message-policy-hides-crash-reason
# and seeds a BROKEN Pod. "worker" crashes on startup because a required
# config file is missing, printing a clear diagnostic line to stdout before
# exiting non-zero - and keeps CrashLoopBackOff-ing. Its
# terminationMessagePolicy is left at the default, "File", which means
# Kubernetes only looks at /dev/termination-log for a crash reason - a path
# "worker" never writes to - so
# .status.containerStatuses[].lastState.terminated.message stays empty
# every time it crashes, hiding the actual diagnostic ("kubectl describe
# pod" would show nothing useful under "Last State"). "sidecar" is an
# unrelated second container, not part of the bug.
set -euo pipefail

QUESTION_ID="q102-49-termination-message-policy-hides-crash-reason${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: crashy-worker
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  containers:
    - name: worker
      image: busybox:1.36
      command: ["sh", "-c", "echo 'FATAL: config file missing at /etc/app/config.yaml'; sleep 2; exit 1"]
      resources:
        requests:
          cpu: 25m
          memory: 32Mi
        limits:
          cpu: 50m
          memory: 64Mi
    - name: sidecar
      image: busybox:1.36
      command: ["sh", "-c", "while true; do sleep 3600; done"]
      resources:
        requests:
          cpu: 25m
          memory: 32Mi
        limits:
          cpu: 50m
          memory: 64Mi
EOF

echo "setup.sh: $QUESTION_ID ready"
