#!/usr/bin/env bash
# Idempotent: creates/resets namespace q102-50-livenessprobe-wrong-path-crashloop
# and seeds a BROKEN Pod. "app" is completely healthy - it touches
# /tmp/healthy every 2 seconds forever - but its livenessProbe execs
# `test -f /tmp/health` (missing the trailing "y"), a path that never
# exists, so the probe always fails. The kubelet repeatedly kills and
# restarts "app" on a perfectly healthy process: kubectl get pod shows
# rising RESTARTS and CrashLoopBackOff, even though nothing is actually
# wrong with the application itself. "sidecar" is an unrelated second
# container, not part of the bug.
set -euo pipefail

QUESTION_ID="q102-50-livenessprobe-wrong-path-crashloop${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: false-alarm-app
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  containers:
    - name: app
      image: busybox:1.36
      command: ["sh", "-c", "while true; do touch /tmp/healthy; sleep 2; done"]
      livenessProbe:
        exec:
          command: ["sh", "-c", "test -f /tmp/health"]
        periodSeconds: 3
        failureThreshold: 1
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
