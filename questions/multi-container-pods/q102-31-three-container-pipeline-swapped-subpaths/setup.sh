#!/usr/bin/env bash
# Idempotent: creates/resets namespace
# q102-31-three-container-pipeline-swapped-subpaths and seeds a BROKEN
# 3-container pipeline pod. All three containers mount one shared emptyDir
# volume ("pipeline-data"), each through a distinct subPath - but two of
# the four volumeMounts[].subPath values were accidentally swapped when the
# manifest was written:
#   - "transformer"'s /in mount got subPath "stage2" (its own write-stage)
#     instead of "stage1" (producer's stage) - so it never sees producer's
#     file and never writes /out/payload.txt at all.
#   - "consumer"'s /final mount got subPath "stage1" (producer's raw
#     stage) instead of "stage2" (transformer's output stage) - so it
#     silently reads producer's untouched raw payload instead of
#     transformer's processed output.
# Nothing crashes (no CrashLoopBackOff, no restarts) - the Pod reports
# Running 3/3 immediately, but the pipeline produces the WRONG final
# answer end to end, which is the actual bug to diagnose and fix.
set -euo pipefail

QUESTION_ID="q102-31-three-container-pipeline-swapped-subpaths${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: pipeline-stages
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  containers:
    - name: producer
      image: busybox:1.36
      command: ["sh", "-c", "echo batch-payload-4471 > /data/payload.txt; while true; do sleep 3600; done"]
      resources:
        requests:
          cpu: 25m
          memory: 32Mi
        limits:
          cpu: 50m
          memory: 64Mi
      volumeMounts:
        - name: pipeline-data
          mountPath: /data
          subPath: stage1
    - name: transformer
      image: busybox:1.36
      command: ["sh", "-c", "i=0; while [ \$i -lt 60 ]; do if [ -f /in/payload.txt ] && [ ! -f /out/payload.txt ]; then printf 'TRANSFORMED:' > /out/payload.txt; cat /in/payload.txt >> /out/payload.txt; fi; i=\$((i+1)); sleep 3; done; while true; do sleep 3600; done"]
      resources:
        requests:
          cpu: 25m
          memory: 32Mi
        limits:
          cpu: 50m
          memory: 64Mi
      volumeMounts:
        - name: pipeline-data
          mountPath: /in
          subPath: stage2
        - name: pipeline-data
          mountPath: /out
          subPath: stage2
    - name: consumer
      image: busybox:1.36
      command: ["sh", "-c", "while true; do sleep 3600; done"]
      resources:
        requests:
          cpu: 25m
          memory: 32Mi
        limits:
          cpu: 50m
          memory: 64Mi
      volumeMounts:
        - name: pipeline-data
          mountPath: /final
          subPath: stage1
  volumes:
    - name: pipeline-data
      emptyDir: {}
EOF

echo "setup.sh: $QUESTION_ID ready"
