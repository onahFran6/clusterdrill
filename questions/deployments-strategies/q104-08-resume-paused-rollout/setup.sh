#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q104-08-resume-paused-rollout${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: reporting
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 3
  selector:
    matchLabels:
      app: reporting
  template:
    metadata:
      labels:
        app: reporting
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: reporting
          image: nginx:1.24-alpine
EOF

kubectl rollout status deployment/reporting -n "$QUESTION_ID" --timeout=60s || true

kubectl rollout pause deployment/reporting -n "$QUESTION_ID"
kubectl set image deployment/reporting reporting=nginx:1.25-alpine -n "$QUESTION_ID"

echo "setup.sh: $QUESTION_ID ready (paused, with a pending image change queued up)"
