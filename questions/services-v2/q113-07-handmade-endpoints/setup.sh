#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q113-07-handmade-endpoints${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: legacy
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  containers:
    - name: legacy
      image: busybox:1.36
      command: ["sh", "-c", "mkdir -p /www && echo legacy server ok > /www/index.html && httpd -f -p 80 -h /www"]
      ports:
        - containerPort: 80
EOF

kubectl wait --for=condition=Ready pod/legacy -n "$QUESTION_ID" --timeout=60s || true

echo "setup.sh: $QUESTION_ID ready"
