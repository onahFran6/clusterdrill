#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q109-50-crashloop-readonly-volume-mismatch${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: session-tracker
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  containers:
    - name: session-tracker
      image: busybox:1.36
      command: ["sh", "-c", "echo start > /var/run/app/session.pid && sleep 3600"]
      securityContext:
        readOnlyRootFilesystem: true
EOF

echo "setup.sh: $QUESTION_ID ready (session-tracker crash-looping - readOnlyRootFilesystem with no writable volume for /var/run/app)"
