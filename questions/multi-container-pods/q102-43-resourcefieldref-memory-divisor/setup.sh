#!/usr/bin/env bash
# Idempotent: creates/resets namespace q102-43-resourcefieldref-memory-divisor
# and seeds a BROKEN Pod. "worker" exposes its own memory LIMIT to itself as
# an env var via the Downward API's resourceFieldRef (not fieldRef - this is
# the container-resources flavor, not the Pod-metadata flavor), so it can
# size an in-memory cache proportionally. Its divisor is wrong ("1", i.e.
# raw bytes) instead of "1Mi" (mebibytes), so MEM_LIMIT_MB ends up holding
# the byte count (67108864) instead of the intended mebibyte count (64).
# Nothing crashes - "worker" just writes the wrong number. "validator" is an
# unrelated second container, not part of the bug.
set -euo pipefail

QUESTION_ID="q102-43-resourcefieldref-memory-divisor${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: sized-worker
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  containers:
    - name: worker
      image: busybox:1.36
      command: ["sh", "-c", "mkdir -p /data; echo \"\$MEM_LIMIT_MB\" > /data/mem_limit_mb.txt; while true; do sleep 3600; done"]
      env:
        - name: MEM_LIMIT_MB
          valueFrom:
            resourceFieldRef:
              resource: limits.memory
              divisor: "1"
      resources:
        requests:
          cpu: 50m
          memory: 32Mi
        limits:
          cpu: 100m
          memory: 64Mi
    - name: validator
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
