#!/usr/bin/env bash
# Idempotent: creates/resets namespace q106-26-role-list-watch-only-no-get and
# seeds a ServiceAccount with no Role/RoleBinding yet.
set -euo pipefail

QUESTION_ID="q106-26-role-list-watch-only-no-get${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
kind: ServiceAccount
metadata:
  name: dashboard-sa
  labels:
    clusterdrill-question: $QUESTION_ID
EOF

echo "setup.sh: $QUESTION_ID ready"
