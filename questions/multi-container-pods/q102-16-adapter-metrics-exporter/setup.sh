#!/usr/bin/env bash
# Idempotent: creates/resets namespace and seeds the single-container
# "metrics-app" pod that the candidate must extend with an adapter container.
set -euo pipefail

QUESTION_ID="q102-16-adapter-metrics-exporter${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: metrics-app
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  containers:
    - name: app
      image: busybox:1.36
      command: ["sh", "-c", "while true; do echo requests_total:42 > /metrics/raw.txt; sleep 5; done"]
      volumeMounts:
        - name: metrics-vol
          mountPath: /metrics
  volumes:
    - name: metrics-vol
      emptyDir: {}
EOF

echo "setup.sh: $QUESTION_ID ready"
