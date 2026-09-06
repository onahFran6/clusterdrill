#!/usr/bin/env bash
# Idempotent: creates/resets namespace q102-47-readonlyrootfs-sidecar-needs-scratch-volume
# and seeds a BROKEN Pod. "app" is unrelated and idles fine. "lock-manager"
# is hardened with securityContext.readOnlyRootFilesystem: true (a real,
# common security baseline) and needs to write a small lock file to /tmp as
# part of its normal operation - but with no writable volume mounted at
# /tmp, every write attempt against the read-only root filesystem fails
# with "Read-only file system". The container process itself catches that
# error and keeps looping rather than crashing, so kubectl get pod shows
# 2/2 Running the whole time, masking that "lock-manager" can never
# actually do its job.
set -euo pipefail

QUESTION_ID="q102-47-readonlyrootfs-sidecar-needs-scratch-volume${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: hardened-lock-app
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  containers:
    - name: app
      image: busybox:1.36
      command: ["sh", "-c", "while true; do sleep 3600; done"]
      resources:
        requests:
          cpu: 25m
          memory: 32Mi
        limits:
          cpu: 50m
          memory: 64Mi
    - name: lock-manager
      image: busybox:1.36
      securityContext:
        readOnlyRootFilesystem: true
      command: ["sh", "-c", "while true; do echo locked > /tmp/lock.txt 2>/dev/null || true; sleep 5; done"]
      resources:
        requests:
          cpu: 25m
          memory: 32Mi
        limits:
          cpu: 50m
          memory: 64Mi
EOF

echo "setup.sh: $QUESTION_ID ready"
