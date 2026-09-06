#!/usr/bin/env bash
# Idempotent: creates/resets namespace q105-02-configmap-from-file-volume,
# writes the source file to /tmp, and seeds the starting pod. Every cluster
# object created here carries the label
# clusterdrill-question=q105-02-configmap-from-file-volume.

set -euo pipefail

QUESTION_ID="q105-02-configmap-from-file-volume${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

# Source file for the ConfigMap --from-file step, in this question's own
# terminal working directory (not a shared /tmp path - see
# question_workdir() in lib/grading.sh) so it's exactly where the
# candidate's terminal actually starts.
WORK_DIR="$(question_workdir "$QUESTION_ID")"
cat > "$WORK_DIR/q105-02-nginx.conf" <<'EOF'
server {
    listen 8080;
    location / {
        return 200 'q105-02 ok';
    }
}
EOF

kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: web-server
  labels:
    app: web-server
    clusterdrill-question: $QUESTION_ID
spec:
  containers:
    - name: web-server
      image: nginx:1.25-alpine
EOF

kubectl wait --for=condition=Ready pod/web-server -n "$QUESTION_ID" --timeout=60s || true

echo "setup.sh: $QUESTION_ID ready"
