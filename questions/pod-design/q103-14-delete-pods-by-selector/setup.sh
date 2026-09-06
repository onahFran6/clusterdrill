#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q103-14-delete-pods-by-selector${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

for name_lifecycle in "keep-1:keep" "keep-2:keep" "scratch-1:scratch" "scratch-2:scratch" "scratch-3:scratch"; do
  IFS=':' read -r name lifecycle <<< "$name_lifecycle"
  kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: $name
  labels:
    lifecycle: $lifecycle
    clusterdrill-question: $QUESTION_ID
spec:
  containers:
    - name: $name
      image: busybox:1.36
      command: ["sleep", "3600"]
EOF
done

echo "setup.sh: $QUESTION_ID ready"
