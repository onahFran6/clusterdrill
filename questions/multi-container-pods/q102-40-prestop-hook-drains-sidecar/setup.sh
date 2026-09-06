#!/usr/bin/env bash
# Idempotent: creates/resets namespace q102-40-prestop-hook-drains-sidecar
# and seeds a BROKEN Pod. "log-shipper" batches log lines in memory and only
# flushes them to /data/shipped.log every 30 seconds - normal operation is
# fine, but it has NO preStop hook, so when the Pod is deleted, Kubernetes
# sends SIGTERM immediately and (after the grace period) SIGKILLs it,
# possibly losing whatever batch hadn't been flushed yet. terminationGrace-
# PeriodSeconds is also left at the low default (a few seconds), too short
# for any flush-on-shutdown logic to matter anyway. Nothing about this is
# visible in steady-state kubectl get pod output - it only shows up during
# shutdown - so this question is graded structurally: a correct preStop
# hook plus a long enough terminationGracePeriodSeconds, verified once the
# Pod is Running.
set -euo pipefail

QUESTION_ID="q102-40-prestop-hook-drains-sidecar${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: batching-shipper
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
    - name: log-shipper
      image: busybox:1.36
      command: ["sh", "-c", "mkdir -p /data; touch /data/buffer.log; while true; do sleep 30; cat /data/buffer.log >> /data/shipped.log; > /data/buffer.log; done"]
      volumeMounts:
        - name: data
          mountPath: /data
      resources:
        requests:
          cpu: 25m
          memory: 32Mi
        limits:
          cpu: 50m
          memory: 64Mi
  volumes:
    - name: data
      emptyDir: {}
EOF

echo "setup.sh: $QUESTION_ID ready"
