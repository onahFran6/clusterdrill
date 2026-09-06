#!/usr/bin/env bash
# Idempotent: creates/resets namespace q102-20-init-container-wrong-image-tag
# and seeds a BROKEN pod: init container "fetch-config" references image
# busybox:99.99, a tag that does not exist, so it sits in
# ImagePullBackOff/ErrImagePull forever and the main container "report-app"
# never starts.
set -euo pipefail

QUESTION_ID="q102-20-init-container-wrong-image-tag${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: report-gen
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  initContainers:
    - name: fetch-config
      image: busybox:99.99
      command: ["sh", "-c", "echo fetched > /tmp/config.txt"]
  containers:
    - name: report-app
      image: busybox:1.36
      command: ["sh", "-c", "sleep 3600"]
EOF

echo "setup.sh: $QUESTION_ID ready"
