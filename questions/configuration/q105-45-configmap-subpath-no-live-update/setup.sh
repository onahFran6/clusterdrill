#!/usr/bin/env bash
# Idempotent: creates/resets namespace
# q105-45-configmap-subpath-no-live-update and seeds the starting ConfigMap
# and subPath-mounting pod. Every cluster object created here carries the
# label clusterdrill-question=q105-45-configmap-subpath-no-live-update
#.

set -euo pipefail

QUESTION_ID="q105-45-configmap-subpath-no-live-update${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: app-version
  labels:
    clusterdrill-question: $QUESTION_ID
data:
  version.txt: "v1.0.0"
EOF

kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: version-display
  labels:
    app: version-display
    clusterdrill-question: $QUESTION_ID
spec:
  containers:
    - name: version-display
      image: nginx:1.25-alpine
      volumeMounts:
        - name: version-vol
          mountPath: /usr/share/nginx/html/version.txt
          subPath: version.txt
  volumes:
    - name: version-vol
      configMap:
        name: app-version
EOF

kubectl wait --for=condition=Ready pod/version-display -n "$QUESTION_ID" --timeout=60s || true

echo "setup.sh: $QUESTION_ID ready"
