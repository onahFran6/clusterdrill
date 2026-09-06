#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q106-40-serviceaccount-automount-pod-override-true${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

# The ServiceAccount disables automount at its own level - the candidate's
# job is to override that at the Pod level, not touch the ServiceAccount.
kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: token-needer
  labels:
    clusterdrill-question: $QUESTION_ID
automountServiceAccountToken: false
EOF

echo "setup.sh: $QUESTION_ID ready (no Pod exists yet - candidate creates it)"
