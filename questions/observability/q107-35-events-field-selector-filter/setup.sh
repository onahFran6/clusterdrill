#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q107-35-events-field-selector-filter${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
kind: Pod
metadata:
  name: healthy-app
  labels:
    app: healthy-app
    clusterdrill-question: $QUESTION_ID
spec:
  containers:
    - name: healthy-app
      image: nginx:1.25-alpine
---
apiVersion: v1
kind: Pod
metadata:
  name: broken-app
  labels:
    app: broken-app
    clusterdrill-question: $QUESTION_ID
spec:
  containers:
    - name: broken-app
      image: nginx:this-tag-does-not-exist-q107-35
EOF

# Give the kubelet a moment to actually attempt the pull and emit the
# Warning event before the candidate connects.
sleep 15

echo "setup.sh: $QUESTION_ID ready (healthy-app Running, broken-app generating ImagePull Warning events)"
