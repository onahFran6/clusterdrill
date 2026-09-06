#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q107-22-multi-container-shared-log-volume${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

# Seed a pod with a writer container that appends to audit.log on a shared
# emptyDir volume, and a sidecar shipper container that tails the wrong
# filename (access.log) on that same volume - it CrashLoopBackOffs until
# the candidate fixes the filename it tails.
kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: audit-logger
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  volumes:
    - name: logs
      emptyDir: {}
  containers:
    - name: writer
      image: busybox:1.36
      command:
        - sh
        - -c
        - "while true; do date >> /var/log/app/audit.log; sleep 2; done"
      volumeMounts:
        - name: logs
          mountPath: /var/log/app
    - name: shipper
      image: busybox:1.36
      command:
        - sh
        - -c
        - "tail -f /logs/access.log"
      volumeMounts:
        - name: logs
          mountPath: /logs
EOF

echo "setup.sh: $QUESTION_ID ready"
