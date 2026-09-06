#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q107-37-custom-columns-extraction${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: fleet-alpha
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  containers:
    - name: fleet-alpha
      image: nginx:1.24-alpine
---
apiVersion: v1
kind: Pod
metadata:
  name: fleet-beta
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  containers:
    - name: fleet-beta
      image: nginx:1.25-alpine
---
apiVersion: v1
kind: Pod
metadata:
  name: fleet-gamma
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  containers:
    - name: fleet-gamma
      image: busybox:1.36
EOF

echo "setup.sh: $QUESTION_ID ready"
