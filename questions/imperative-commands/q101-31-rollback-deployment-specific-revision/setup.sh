#!/usr/bin/env bash
# Idempotent: creates/resets namespace q101-31-... and rolls a Deployment
# named orders-api through 4 revisions:
#   revision 1: nginx:1.20-alpine           - healthy
#   revision 2: nginx:1.23-alpine           - healthy (the correct rollback target)
#   revision 3: nginx:1.24-alpine-missing   - broken (bad tag, ImagePullBackOff)
#   revision 4: nginx:1.25-alpine-missing   - broken, current (bad tag, ImagePullBackOff)
#
# revision 2 is deliberately neither revision 1 (the oldest) nor revision 3
# (the immediately-previous one, which is ALSO broken) - the candidate must
# inspect each revision's pod template via `rollout history --revision=N`
# rather than assume "oldest" or "one step back" is safe.

set -euo pipefail

QUESTION_ID="q101-31-rollback-deployment-specific-revision${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

# Revision 1: healthy
kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: orders-api
  labels:
    clusterdrill-question: $QUESTION_ID
  annotations:
    kubernetes.io/change-cause: "deploy 1: initial rollout"
spec:
  replicas: 2
  selector:
    matchLabels:
      app: orders-api
  template:
    metadata:
      labels:
        app: orders-api
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: orders-api
          image: nginx:1.20-alpine
          resources:
            requests: {cpu: 25m, memory: 32Mi}
            limits: {cpu: 50m, memory: 64Mi}
EOF
kubectl rollout status deployment/orders-api -n "$QUESTION_ID" --timeout=60s

# Revision 2: healthy - the correct rollback target, but not the oldest and
# not the one immediately before the current (broken) revision.
kubectl set image deployment/orders-api orders-api=nginx:1.23-alpine -n "$QUESTION_ID"
kubectl annotate deployment orders-api -n "$QUESTION_ID" \
  kubernetes.io/change-cause="deploy 2: stable rollout" --overwrite
kubectl rollout status deployment/orders-api -n "$QUESTION_ID" --timeout=60s

# Revision 3: broken - bad tag, never becomes ready. Immediately precedes
# the current revision, so a plain `rollout undo` (no --to-revision) lands
# here and is still broken.
kubectl set image deployment/orders-api orders-api=nginx:1.24-alpine-missing -n "$QUESTION_ID"
kubectl annotate deployment orders-api -n "$QUESTION_ID" \
  kubernetes.io/change-cause="deploy 3: hotfix attempt" --overwrite
kubectl rollout status deployment/orders-api -n "$QUESTION_ID" --timeout=20s || true

# Revision 4 (current): broken - a different bad tag, so it's distinguishable
# from revision 3 and from any accidental "undo one step" outcome.
kubectl set image deployment/orders-api orders-api=nginx:1.25-alpine-missing -n "$QUESTION_ID"
kubectl annotate deployment orders-api -n "$QUESTION_ID" \
  kubernetes.io/change-cause="deploy 4: latest rollout" --overwrite
kubectl rollout status deployment/orders-api -n "$QUESTION_ID" --timeout=20s || true

echo "setup.sh: $QUESTION_ID ready (orders-api stuck on broken revision 4; revision 2 is the healthy target)"
