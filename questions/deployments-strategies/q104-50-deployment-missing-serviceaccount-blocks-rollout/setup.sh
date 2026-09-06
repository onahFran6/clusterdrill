#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q104-50-deployment-missing-serviceaccount-blocks-rollout${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
kind: ServiceAccount
metadata:
  name: payments-runner
  labels:
    clusterdrill-question: $QUESTION_ID
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: payments-worker
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 2
  selector:
    matchLabels:
      app: payments-worker
  template:
    metadata:
      labels:
        app: payments-worker
        clusterdrill-question: $QUESTION_ID
    spec:
      # Bug: extra 'n' - this ServiceAccount does not exist, so pod
      # creation is rejected by admission before any pod object even
      # appears.
      serviceAccountName: payments-runnner
      containers:
        - name: payments-worker
          image: busybox:1.36
          command: ["sleep", "3600"]
EOF

# Don't wait for rollout status - it will never succeed (no pods can even
# be created). Give the controller a moment to attempt (and fail) pod
# creation so the stuck state is visibly established.
sleep 5

echo "setup.sh: $QUESTION_ID ready (payments-worker blocked on typoed serviceAccountName)"
