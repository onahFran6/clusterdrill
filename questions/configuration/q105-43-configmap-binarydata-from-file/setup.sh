#!/usr/bin/env bash
# Idempotent: creates/resets namespace
# q105-43-configmap-binarydata-from-file, seeds ~/assets/logo.bin (a
# deterministic, non-UTF-8 byte sequence - starts with 0xFF 0xFE, which are
# never valid UTF-8 lead bytes, so `kubectl create configmap --from-file`
# is guaranteed to route it into binaryData) and the starting pod.

set -euo pipefail

QUESTION_ID="q105-43-configmap-binarydata-from-file${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: asset-server
  labels:
    app: asset-server
    clusterdrill-question: $QUESTION_ID
spec:
  containers:
    - name: asset-server
      image: nginx:1.25-alpine
EOF

kubectl wait --for=condition=Ready pod/asset-server -n "$QUESTION_ID" --timeout=60s || true

WORK_DIR="$(question_workdir "$QUESTION_ID")"
mkdir -p "$WORK_DIR/assets"
printf '\xff\xfe\x01\x02\x03\x04\x05\x06' > "$WORK_DIR/assets/logo.bin"

echo "setup.sh: $QUESTION_ID ready"
