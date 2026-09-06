#!/usr/bin/env bash
# Idempotent: creates/resets namespace q102-26-poststart-marker-gates-sidecar-start
# and seeds a BROKEN pod: "app"'s postStart lifecycle hook writes its "ready"
# marker to /tmp/ready instead of /shared/ready. /tmp is app's own container
# filesystem, not the shared emptyDir mount, so the write itself succeeds
# (exit 0 - the hook never fails, so kubelet never kills/restarts "app" over
# it) but the sidecar "log-tailer", which polls for /shared/ready on the
# *shared* volume, never sees it and loops forever without starting its real
# work (tailing app.log).
set -euo pipefail

QUESTION_ID="q102-26-poststart-marker-gates-sidecar-start${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: staged-app
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  containers:
    - name: app
      image: busybox:1.36
      command: ["sh", "-c", "touch /shared/app.log; while true; do echo \"\$(date -u) app heartbeat\" >> /shared/app.log; sleep 5; done"]
      lifecycle:
        postStart:
          exec:
            command: ["sh", "-c", "sleep 2 && echo ready > /tmp/ready"]
      resources:
        requests:
          cpu: 25m
          memory: 32Mi
        limits:
          cpu: 50m
          memory: 64Mi
      volumeMounts:
        - name: shared
          mountPath: /shared
    - name: log-tailer
      image: busybox:1.36
      command: ["sh", "-c", "until [ -f /shared/ready ]; do sleep 2; done; touch /shared/log-tailer-active; tail -f /shared/app.log"]
      resources:
        requests:
          cpu: 25m
          memory: 32Mi
        limits:
          cpu: 50m
          memory: 64Mi
      volumeMounts:
        - name: shared
          mountPath: /shared
  volumes:
    - name: shared
      emptyDir: {}
EOF

echo "setup.sh: $QUESTION_ID ready"
