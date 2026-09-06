#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q106-50-networkpolicy-namespaceselector-and-podselector-and${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
kubectl label namespace "$QUESTION_ID" "team=platform" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: secrets-vault
  labels:
    app: secrets-vault
    clusterdrill-question: $QUESTION_ID
spec:
  containers:
    - name: secrets-vault
      image: nginx:1.25-alpine
      ports:
        - containerPort: 80
EOF

echo "setup.sh: $QUESTION_ID ready (no NetworkPolicy exists yet - candidate creates it; namespace already labeled team=platform)"
