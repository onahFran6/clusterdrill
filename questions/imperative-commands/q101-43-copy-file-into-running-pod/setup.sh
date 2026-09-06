#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q101-43-copy-file-into-running-pod${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: archive-box
  labels:
    app: archive-box
    clusterdrill-question: $QUESTION_ID
spec:
  containers:
    - name: archive-box
      image: busybox:1.36
      command: ["sh", "-c", "mkdir -p /data && sleep 3600"]
      resources:
        requests:
          cpu: 25m
          memory: 32Mi
        limits:
          cpu: 50m
          memory: 64Mi
EOF

kubectl wait --for=condition=Ready pod/archive-box -n "$QUESTION_ID" --timeout=60s || true

WORKDIR="$(question_workdir "$QUESTION_ID")"
cat > "$WORKDIR/manifest.txt" <<'EOF'
build=482
channel=stable
EOF

echo "setup.sh: $QUESTION_ID ready"
