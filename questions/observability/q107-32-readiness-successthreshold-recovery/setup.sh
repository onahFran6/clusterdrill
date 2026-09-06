#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q107-32-readiness-successthreshold-recovery${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

# readinessProbe has no successThreshold set (defaults to 1) - the
# candidate must require 3 consecutive successes before Ready, without
# changing anything else about the probe.
kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: flaky-backend
  labels:
    app: flaky-backend
    clusterdrill-question: $QUESTION_ID
spec:
  containers:
    - name: flaky-backend
      image: nginx:1.25-alpine
      readinessProbe:
        httpGet:
          path: /
          port: 80
        periodSeconds: 2
EOF

kubectl wait --for=condition=Ready pod/flaky-backend -n "$QUESTION_ID" --timeout=60s || true

echo "setup.sh: $QUESTION_ID ready"
