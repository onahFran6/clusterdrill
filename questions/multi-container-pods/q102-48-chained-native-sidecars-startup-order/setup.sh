#!/usr/bin/env bash
# Idempotent: creates/resets namespace q102-48-chained-native-sidecars-startup-order
# and seeds a BROKEN Pod. Two native sidecars (init containers with
# restartPolicy: Always) form a dependency chain: "cache-warmer" writes
# /run/warm/ready a few seconds after it starts, and "index-builder" needs
# that file to exist before it can do its own work - its startupProbe waits
# for it. Kubernetes starts native sidecars IN ORDER, only starting the
# NEXT one once the current one's own startupProbe has passed - but here
# the initContainers list has "index-builder" listed BEFORE "cache-warmer",
# so "index-builder" starts first and its startupProbe waits forever for a
# file that "cache-warmer" (which never even gets a chance to start) was
# supposed to create. The whole Pod is stuck at Init, never reaching
# "cache-warmer" or the main container "web": kubectl get pod shows 0/3,
# Init:0/2, indefinitely.
set -euo pipefail

QUESTION_ID="q102-48-chained-native-sidecars-startup-order${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: chained-sidecars-app
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  initContainers:
    - name: index-builder
      image: busybox:1.36
      restartPolicy: Always
      command: ["sh", "-c", "while true; do sleep 3600; done"]
      startupProbe:
        exec:
          command: ["sh", "-c", "test -f /run/warm/ready"]
        periodSeconds: 2
        failureThreshold: 5
      volumeMounts:
        - name: warm-signal
          mountPath: /run/warm
      resources:
        requests:
          cpu: 25m
          memory: 32Mi
        limits:
          cpu: 50m
          memory: 64Mi
    - name: cache-warmer
      image: busybox:1.36
      restartPolicy: Always
      command: ["sh", "-c", "sleep 3; mkdir -p /run/warm; touch /run/warm/ready; while true; do sleep 3600; done"]
      startupProbe:
        exec:
          command: ["sh", "-c", "test -f /run/warm/ready"]
        periodSeconds: 2
        failureThreshold: 5
      volumeMounts:
        - name: warm-signal
          mountPath: /run/warm
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
  volumes:
    - name: warm-signal
      emptyDir: {}
EOF

echo "setup.sh: $QUESTION_ID ready"
