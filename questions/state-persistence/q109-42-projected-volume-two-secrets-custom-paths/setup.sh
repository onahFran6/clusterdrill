#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q109-42-projected-volume-two-secrets-custom-paths${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
kind: Secret
metadata:
  name: db-credentials
  labels:
    clusterdrill-question: $QUESTION_ID
stringData:
  password: hunter2
---
apiVersion: v1
kind: Secret
metadata:
  name: api-credentials
  labels:
    clusterdrill-question: $QUESTION_ID
stringData:
  token: abc123
EOF

echo "setup.sh: $QUESTION_ID ready"
