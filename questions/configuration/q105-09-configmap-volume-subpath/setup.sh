#!/usr/bin/env bash
# Idempotent: creates/resets namespace q105-09-configmap-volume-subpath and
# seeds the ConfigMap plus starting pod (which itself lays down an
# unrelated file inside the container image path via its command). Every
# cluster object created here carries the label
# clusterdrill-question=q105-09-configmap-volume-subpath.

set -euo pipefail

QUESTION_ID="q105-09-configmap-volume-subpath${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
kind: ConfigMap
metadata:
  name: site-config
  labels:
    clusterdrill-question: $QUESTION_ID
data:
  index.html: |
    <html><body>q105-09 landing page</body></html>
---
apiVersion: v1
kind: Pod
metadata:
  name: landing-page
  labels:
    app: landing-page
    clusterdrill-question: $QUESTION_ID
spec:
  containers:
    - name: landing-page
      image: nginx:1.25-alpine
      command: ["sh", "-c"]
      args:
        - "echo already-here > /usr/share/nginx/html/existing-notice.txt && exec nginx -g 'daemon off;'"
EOF

kubectl wait --for=condition=Ready pod/landing-page -n "$QUESTION_ID" --timeout=60s || true

echo "setup.sh: $QUESTION_ID ready"
