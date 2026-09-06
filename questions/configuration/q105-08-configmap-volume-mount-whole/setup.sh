#!/usr/bin/env bash
# Idempotent: creates/resets namespace q105-08-configmap-volume-mount-whole
# and seeds the ConfigMap plus starting pod. Every cluster object created
# here carries the label clusterdrill-question=q105-08-configmap-volume-mount-whole
#.

set -euo pipefail

QUESTION_ID="q105-08-configmap-volume-mount-whole${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: app-config
  labels:
    clusterdrill-question: $QUESTION_ID
data:
  app.properties: |
    retries=3
  logging.properties: |
    level=INFO
---
apiVersion: v1
kind: Pod
metadata:
  name: report-service
  labels:
    app: report-service
    clusterdrill-question: $QUESTION_ID
spec:
  containers:
    - name: report-service
      image: nginx:1.25-alpine
EOF

kubectl wait --for=condition=Ready pod/report-service -n "$QUESTION_ID" --timeout=60s || true

echo "setup.sh: $QUESTION_ID ready"
