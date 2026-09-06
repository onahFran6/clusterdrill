#!/usr/bin/env bash
# Idempotent: creates/resets namespace q102-34-init-container-wrong-workingdir
# and seeds a BROKEN Pod. Init container "stager" writes its handoff file
# using a RELATIVE path ("handoff.txt", no leading slash) - where that file
# actually lands depends on the container's workingDir. The shared emptyDir
# volume "stage-data" is mounted at /stage, but "stager"'s workingDir is set
# to /tmp instead of /stage, so "handoff.txt" is written into /tmp inside
# stager's own throwaway filesystem - never into the shared volume. The init
# container itself exits 0 (nothing crashes, nothing errors), so the Pod
# proceeds straight to the main container and reports 2/2 Running - but
# "consumer" never finds /consume/handoff.txt because it was never actually
# written into the shared volume.
set -euo pipefail

QUESTION_ID="q102-34-init-container-wrong-workingdir${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: handoff-app
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  initContainers:
    - name: stager
      image: busybox:1.36
      command: ["sh", "-c", "echo shipment-ready-778 > handoff.txt"]
      workingDir: /tmp
      volumeMounts:
        - name: stage-data
          mountPath: /stage
      resources:
        requests:
          cpu: 25m
          memory: 32Mi
        limits:
          cpu: 50m
          memory: 64Mi
  containers:
    - name: consumer
      image: busybox:1.36
      command: ["sh", "-c", "while true; do sleep 3600; done"]
      volumeMounts:
        - name: stage-data
          mountPath: /consume
      resources:
        requests:
          cpu: 25m
          memory: 32Mi
        limits:
          cpu: 50m
          memory: 64Mi
  volumes:
    - name: stage-data
      emptyDir: {}
EOF

echo "setup.sh: $QUESTION_ID ready"
