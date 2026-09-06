#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q104-49-rollback-fails-no-history-fix-forward${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

# Broken from the very first (and only) apply - never once healthy, so
# there is no earlier, working revision for `kubectl rollout undo` to
# target.
kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: pricing-sync
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 2
  selector:
    matchLabels:
      app: pricing-sync
  template:
    metadata:
      labels:
        app: pricing-sync
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: pricing-sync
          image: alpine:3.199
          command: ["sleep", "3600"]
EOF

# Don't wait for rollout status - it will never succeed (the tag doesn't
# exist). Give the kubelet a moment to actually attempt (and fail) the pull.
sleep 5

echo "setup.sh: $QUESTION_ID ready (pricing-sync broken from its only revision, image alpine:3.199)"
