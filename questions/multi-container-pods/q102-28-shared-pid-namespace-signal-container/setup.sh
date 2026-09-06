#!/usr/bin/env bash
# Idempotent: creates/resets namespace and seeds the "config-reload-app" pod
# WITHOUT spec.shareProcessNamespace, so 'watcher' can never see (let alone
# signal) 'main's process - each container has its own isolated PID
# namespace by default, so watcher's `ps` only ever finds itself.
set -euo pipefail

QUESTION_ID="q102-28-shared-pid-namespace-signal-container${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: config-reload-app
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  containers:
    - name: main
      image: busybox:1.36
      command: ["sh", "-c", "trap 'echo reload-\$(date +%s) >> /tmp/main-reload.log' HUP; i=0; while true; do i=\$((i+1)); echo tick \$i >> /tmp/main-tick.log; sleep 2; done"]
      resources:
        requests:
          cpu: 25m
          memory: 32Mi
        limits:
          cpu: 50m
          memory: 64Mi
    - name: watcher
      image: busybox:1.36
      command: ["sh", "-c", "sleep 5; while true; do PID=\$(ps -o pid,args | grep main-reload.log | grep -v grep | awk '{print \$1}'); if [ -n \"\$PID\" ]; then kill -HUP \$PID; fi; sleep 5; done"]
      resources:
        requests:
          cpu: 25m
          memory: 32Mi
        limits:
          cpu: 50m
          memory: 64Mi
EOF

kubectl wait --for=condition=Ready pod/config-reload-app -n "$QUESTION_ID" --timeout=60s

echo "setup.sh: $QUESTION_ID ready"
