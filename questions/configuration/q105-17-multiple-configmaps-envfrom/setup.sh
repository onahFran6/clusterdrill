#!/usr/bin/env bash
# Idempotent: creates/resets namespace q105-17-multiple-configmaps-envfrom
# and seeds two ConfigMaps plus the starting pod. Every cluster object
# created here carries the label
# clusterdrill-question=q105-17-multiple-configmaps-envfrom.

set -euo pipefail

QUESTION_ID="q105-17-multiple-configmaps-envfrom${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: db-config
  labels:
    clusterdrill-question: $QUESTION_ID
data:
  DB_HOST: db.internal
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: cache-config
  labels:
    clusterdrill-question: $QUESTION_ID
data:
  CACHE_HOST: cache.internal
---
apiVersion: v1
kind: Pod
metadata:
  name: api-gateway
  labels:
    app: api-gateway
    clusterdrill-question: $QUESTION_ID
spec:
  containers:
    - name: api-gateway
      image: nginx:1.25-alpine
EOF

kubectl wait --for=condition=Ready pod/api-gateway -n "$QUESTION_ID" --timeout=60s || true

echo "setup.sh: $QUESTION_ID ready"
