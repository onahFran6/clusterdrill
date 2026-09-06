#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q104-46-rollout-stuck-imagepullbackoff-typo${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: auth-service
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 2
  selector:
    matchLabels:
      app: auth-service
  template:
    metadata:
      labels:
        app: auth-service
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: auth-service
          image: redis:7.2-alpine
EOF

kubectl rollout status deployment/auth-service -n "$QUESTION_ID" --timeout=60s || true

# Now trigger the broken rollout: a typoed tag that will never pull.
kubectl set image deployment/auth-service auth-service=redis:7.2-alpin -n "$QUESTION_ID"
# Don't wait for rollout status here - it will never succeed. Give the
# scheduler/kubelet a moment to actually attempt (and fail) the pull so the
# stuck state is visibly established before the candidate connects.
sleep 5

echo "setup.sh: $QUESTION_ID ready (auth-service rollout stuck on typoed tag redis:7.2-alpin)"
