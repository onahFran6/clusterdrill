#!/usr/bin/env bash
# Idempotent: creates/resets namespace q105-15-immutable-secret and seeds a
# mutable Secret. Every cluster object created here carries the label
# clusterdrill-question=q105-15-immutable-secret.

set -euo pipefail

QUESTION_ID="q105-15-immutable-secret${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: signing-key
  labels:
    clusterdrill-question: $QUESTION_ID
stringData:
  KEY_ID: key-2026-a
EOF

echo "setup.sh: $QUESTION_ID ready"
