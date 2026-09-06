#!/usr/bin/env bash
# Idempotent: creates/resets namespace and seeds a mutable ConfigMap - the
# candidate must mark it immutable without altering its data.

set -euo pipefail

QUESTION_ID="q106-25-configmap-immutable-flag${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  LOG_LEVEL: info
  FEATURE_FLAG: enabled
EOF

echo "setup.sh: $QUESTION_ID ready"
