#!/usr/bin/env bash
# Idempotent: creates/resets namespace and seeds the single-container
# "writer-app" pod that the candidate must extend with a sidecar.
set -euo pipefail

QUESTION_ID="q102-01-sidecar-log-shipper${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: writer-app
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  containers:
    - name: writer
      image: busybox:1.36
      command: ["sh", "-c", "while true; do echo \$(date -u) hello from writer >> /var/log/app/output.log; sleep 5; done"]
      volumeMounts:
        - name: log-data
          mountPath: /var/log/app
  volumes:
    - name: log-data
      emptyDir: {}
EOF

echo "setup.sh: $QUESTION_ID ready"
