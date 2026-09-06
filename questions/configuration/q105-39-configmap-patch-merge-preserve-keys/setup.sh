#!/usr/bin/env bash
# Idempotent: creates/resets namespace
# q105-39-configmap-patch-merge-preserve-keys and seeds the starting
# ConfigMap. Every cluster object created here carries the label
# clusterdrill-question=q105-39-configmap-patch-merge-preserve-keys
#.

set -euo pipefail

QUESTION_ID="q105-39-configmap-patch-merge-preserve-keys${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  LOG_LEVEL: "info"
  TIMEOUT: "30"
EOF

echo "setup.sh: $QUESTION_ID ready"
