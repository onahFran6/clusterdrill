#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q103-13-get-pods-multi-label-selector${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

for name_tier_env in "frontend-a:frontend:prod" "frontend-b:frontend:staging" "backend-a:backend:prod" "backend-b:backend:staging"; do
  IFS=':' read -r name tier env <<< "$name_tier_env"
  kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: $name
  labels:
    tier: $tier
    env: $env
    clusterdrill-question: $QUESTION_ID
spec:
  containers:
    - name: $name
      image: busybox:1.36
      command: ["sleep", "3600"]
EOF
done

echo "setup.sh: $QUESTION_ID ready"
