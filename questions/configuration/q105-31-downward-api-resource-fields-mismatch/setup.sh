#!/usr/bin/env bash
# Idempotent: creates/resets namespace and seeds a multi-container Pod
# 'sidecar-metrics' with containers 'main' (memory limit 200Mi) and 'metrics'
# (memory limit 64Mi). The metrics container's env var CONTAINER_MEM_LIMIT is
# wired via a Downward API resourceFieldRef, but its containerName is
# mistakenly set to 'main' instead of 'metrics', so at startup the metrics
# container writes the WRONG container's memory limit to /tmp/limit. Its
# readiness probe compares /tmp/limit against a second, correctly-wired
# ground-truth env var (METRICS_MEM_LIMIT, containerName: metrics) that the
# candidate must not touch - so the probe only passes once CONTAINER_MEM_LIMIT
# itself resolves to the metrics container's own 64Mi limit.

set -euo pipefail

QUESTION_ID="q105-31-downward-api-resource-fields-mismatch${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

# Deliberately broken: the metrics container's CONTAINER_MEM_LIMIT env var
# uses resourceFieldRef.containerName: main (should be: metrics), so it
# resolves to main's 200Mi limit instead of metrics' own 64Mi limit. The
# metrics container's startup script writes CONTAINER_MEM_LIMIT to /tmp/limit
# once, then its readiness probe repeatedly compares /tmp/limit against
# METRICS_MEM_LIMIT (a second, correctly-wired resourceFieldRef the candidate
# must leave alone) - which fails until CONTAINER_MEM_LIMIT points at the
# right container.
kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: sidecar-metrics
  labels:
    app: sidecar-metrics
    clusterdrill-question: $QUESTION_ID
spec:
  containers:
    - name: main
      image: busybox:1.36
      command: ["sh", "-c", "echo main starting; sleep 3600"]
      resources:
        requests:
          cpu: 25m
          memory: 32Mi
        limits:
          cpu: 50m
          memory: 200Mi
    - name: metrics
      image: busybox:1.36
      command:
        - sh
        - -c
        - |
          echo "\${CONTAINER_MEM_LIMIT}" > /tmp/limit
          echo "metrics starting, wrote \${CONTAINER_MEM_LIMIT} to /tmp/limit"
          sleep 3600
      env:
        - name: CONTAINER_MEM_LIMIT
          valueFrom:
            resourceFieldRef:
              containerName: main
              resource: limits.memory
              divisor: 1Mi
        - name: METRICS_MEM_LIMIT
          valueFrom:
            resourceFieldRef:
              containerName: metrics
              resource: limits.memory
              divisor: 1Mi
      resources:
        requests:
          cpu: 25m
          memory: 32Mi
        limits:
          cpu: 50m
          memory: 64Mi
      readinessProbe:
        exec:
          command:
            - sh
            - -c
            - test "\$(cat /tmp/limit 2>/dev/null)" = "\$METRICS_MEM_LIMIT"
        initialDelaySeconds: 2
        periodSeconds: 3
        failureThreshold: 3
EOF

echo "setup.sh: $QUESTION_ID ready"
