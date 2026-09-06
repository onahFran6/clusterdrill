#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q104-16-rollout-restart-config-change${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
kind: ConfigMap
metadata:
  name: app-settings
  labels:
    clusterdrill-question: $QUESTION_ID
data:
  FEATURE_FLAG: "off"
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: worker-pool
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 3
  selector:
    matchLabels:
      app: worker-pool
  template:
    metadata:
      labels:
        app: worker-pool
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: worker-pool
          image: nginx:1.24-alpine
          envFrom:
            - configMapRef:
                name: app-settings
EOF

kubectl rollout status deployment/worker-pool -n "$QUESTION_ID" --timeout=60s || true

# The ConfigMap changes after the pods are already running - this is the
# "stale env var" gap the candidate has to close without a template edit.
kubectl patch configmap app-settings -n "$QUESTION_ID" --type=merge \
  -p '{"data": {"FEATURE_FLAG": "on"}}'

echo "setup.sh: $QUESTION_ID ready"
