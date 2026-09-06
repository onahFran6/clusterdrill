#!/usr/bin/env bash
# Idempotent: creates/resets namespace
# q105-41-configmap-volume-selected-items-rename and seeds the starting
# ConfigMap and pod. Every cluster object created here carries the label
# clusterdrill-question=q105-41-configmap-volume-selected-items-rename
#.

set -euo pipefail

QUESTION_ID="q105-41-configmap-volume-selected-items-rename${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  header.html: "<h1>Header</h1>"
  footer.html: "<footer>Footer</footer>"
  internal-notes.txt: "DO-NOT-SHIP"
EOF

kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: site-renderer
  labels:
    app: site-renderer
    clusterdrill-question: $QUESTION_ID
spec:
  containers:
    - name: site-renderer
      image: nginx:1.25-alpine
EOF

kubectl wait --for=condition=Ready pod/site-renderer -n "$QUESTION_ID" --timeout=60s || true

echo "setup.sh: $QUESTION_ID ready"
