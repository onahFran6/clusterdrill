#!/usr/bin/env bash
# Idempotent: creates/resets namespace q102-27-native-sidecar-startupprobe-gates-main
# and seeds a BROKEN "gated-app" Pod: "cache-warmer" is a native sidecar
# (initContainer with restartPolicy: Always) that creates the marker file
# /var/run/warmer/ready a few seconds after starting, but its startupProbe
# execs `test -f /var/run/cache/ready` - a path that is never created. The
# probe therefore never succeeds, the kubelet keeps killing/restarting
# cache-warmer once its failureThreshold is hit, and the Pod's main
# container "web" - which is only allowed to start after every native
# sidecar's startupProbe has passed - never starts either. The Pod sits at
# 0/2, Init:0/1, indefinitely.
set -euo pipefail

QUESTION_ID="q102-27-native-sidecar-startupprobe-gates-main${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

# --- The broken Pod --------------------------------------------------------
# cache-warmer writes /var/run/warmer/ready, but the startupProbe checks
# /var/run/cache/ready (a different, never-created path) - so the probe
# never succeeds and "web" never starts.
kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: gated-app
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  initContainers:
    - name: cache-warmer
      image: busybox:1.36
      command: ["sh", "-c", "mkdir -p /var/run/warmer; sleep 3; touch /var/run/warmer/ready; while true; do sleep 30; done"]
      restartPolicy: Always
      startupProbe:
        exec:
          command: ["sh", "-c", "test -f /var/run/cache/ready"]
        periodSeconds: 2
        failureThreshold: 3
      resources:
        requests:
          cpu: 25m
          memory: 32Mi
        limits:
          cpu: 50m
          memory: 64Mi
  containers:
    - name: web
      image: nginx:1.27-alpine
      resources:
        requests:
          cpu: 25m
          memory: 32Mi
        limits:
          cpu: 50m
          memory: 64Mi
EOF

echo "setup.sh: $QUESTION_ID ready"
