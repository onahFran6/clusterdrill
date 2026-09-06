#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q101-11-label-pods-selector${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

for name in batch-a batch-b; do
  kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: $name
  labels:
    role: worker
    clusterdrill-question: $QUESTION_ID
spec:
  containers:
    - name: worker
      image: busybox:1.36
      command: ["sleep", "3600"]
EOF
done

echo "setup.sh: $QUESTION_ID ready"
