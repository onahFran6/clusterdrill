#!/usr/bin/env bash
# Idempotent: creates/resets namespace and seeds the "audit-logger" pod whose
# 'shipper' sidecar container has no volumeMounts section at all, so it can
# never see the log file 'app' writes.
set -euo pipefail

QUESTION_ID="q102-21-sidecar-missing-shared-mountpath${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: audit-logger
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  containers:
    - name: app
      image: busybox:1.36
      command: ["sh", "-c", "while true; do echo \$(date -u) audit event >> /var/log/audit/app.log; sleep 5; done"]
      resources:
        requests:
          cpu: 25m
          memory: 32Mi
        limits:
          cpu: 50m
          memory: 64Mi
      volumeMounts:
        - name: audit-vol
          mountPath: /var/log/audit
    - name: shipper
      image: busybox:1.36
      command: ["sh", "-c", "while true; do if [ -f /var/log/audit/app.log ]; then tail -f /var/log/audit/app.log; else echo waiting for file; sleep 5; fi; done"]
      resources:
        requests:
          cpu: 25m
          memory: 32Mi
        limits:
          cpu: 50m
          memory: 64Mi
  volumes:
    - name: audit-vol
      emptyDir: {}
EOF

echo "setup.sh: $QUESTION_ID ready"
