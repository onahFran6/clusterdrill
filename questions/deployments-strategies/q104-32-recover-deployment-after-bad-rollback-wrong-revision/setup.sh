#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q104-32-recover-deployment-after-bad-rollback-wrong-revision${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

# Revision 1: v1
kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: billing-sync
  labels:
    clusterdrill-question: $QUESTION_ID
  annotations:
    kubernetes.io/change-cause: "initial release v1"
spec:
  replicas: 2
  selector:
    matchLabels:
      app: billing-sync
  template:
    metadata:
      labels:
        app: billing-sync
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: billing-sync
          image: busybox:1.34
          command: ["sleep", "3600"]
          resources:
            requests: {cpu: 25m, memory: 32Mi}
            limits: {cpu: 50m, memory: 64Mi}
EOF
kubectl rollout status deployment/billing-sync -n "$QUESTION_ID" --timeout=60s

# Revision 2: v2 (the current known-good target)
kubectl set image deployment/billing-sync billing-sync=busybox:1.35 -n "$QUESTION_ID"
kubectl annotate deployment billing-sync -n "$QUESTION_ID" \
  kubernetes.io/change-cause="release v2 - current known-good target" --overwrite
kubectl rollout status deployment/billing-sync -n "$QUESTION_ID" --timeout=60s

# Revision 3: v3 (broken - never actually meant to stay live)
kubectl set image deployment/billing-sync billing-sync=busybox:1.36 -n "$QUESTION_ID"
kubectl annotate deployment billing-sync -n "$QUESTION_ID" \
  kubernetes.io/change-cause="release v3 - broken, do not use" --overwrite
kubectl rollout status deployment/billing-sync -n "$QUESTION_ID" --timeout=60s

# The "someone fat-fingered the wrong revision number" mistake - reverts to
# revision 1 (busybox:1.34), the oldest, instead of revision 2 (busybox:1.35).
kubectl rollout undo deployment/billing-sync -n "$QUESTION_ID" --to-revision=1
kubectl rollout status deployment/billing-sync -n "$QUESTION_ID" --timeout=60s

echo "setup.sh: $QUESTION_ID ready (currently on busybox:1.34, should be busybox:1.35)"
