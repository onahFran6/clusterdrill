#!/usr/bin/env bash
# Idempotent: creates/resets namespace
# q101-50-scale-down-to-free-resourcequota, applies a strict ResourceQuota
# (hard.pods=2, tighter than apply_default_resource_limits' own default
# quota) and a Deployment already using up all 2 of those pods, so a new
# pod creation is rejected outright by admission until the candidate scales
# something down to free headroom.

set -euo pipefail

QUESTION_ID="q101-50-scale-down-to-free-resourcequota${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
kind: ResourceQuota
metadata:
  name: task-quota
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  hard:
    pods: "2"
EOF

kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: legacy-batch
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 2
  selector:
    matchLabels:
      app: legacy-batch
  template:
    metadata:
      labels:
        app: legacy-batch
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: legacy-batch
          image: busybox:1.36
          command: ["sleep", "3600"]
          resources:
            requests:
              cpu: 10m
              memory: 16Mi
            limits:
              cpu: 20m
              memory: 32Mi
EOF

kubectl rollout status deployment/legacy-batch -n "$QUESTION_ID" --timeout=60s || true

echo "setup.sh: $QUESTION_ID ready"
