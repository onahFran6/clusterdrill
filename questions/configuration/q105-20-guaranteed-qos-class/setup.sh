#!/usr/bin/env bash
# Idempotent: creates/resets namespace q105-20-guaranteed-qos-class and
# seeds a Burstable-QoS starting pod. Every cluster object created here
# carries the label clusterdrill-question=q105-20-guaranteed-qos-class
#.

set -euo pipefail

QUESTION_ID="q105-20-guaranteed-qos-class${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: critical-job
  labels:
    app: critical-job
    clusterdrill-question: $QUESTION_ID
spec:
  containers:
    - name: critical-job
      image: nginx:1.25-alpine
      resources:
        requests:
          cpu: "200m"
        limits:
          cpu: "500m"
EOF

kubectl wait --for=condition=Ready pod/critical-job -n "$QUESTION_ID" --timeout=60s || true

echo "setup.sh: $QUESTION_ID ready"
