#!/usr/bin/env bash
# Idempotent: creates/resets namespace and applies a 2-container Pod
# without shareProcessNamespace (defaults false) - the 'watchdog' container
# can only see its own process tree via `ps`, not the 'main-app'
# container's, so it can't monitor/signal it as intended.

set -euo pipefail

QUESTION_ID="q107-48-shareprocessnamespace-cross-container-visibility${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: monitored-app
  labels:
    app: monitored-app
    clusterdrill-question: $QUESTION_ID
spec:
  containers:
    - name: main-app
      image: busybox:1.36
      command: ["sh", "-c", "exec sleep 424242"]
    - name: watchdog
      image: busybox:1.36
      command: ["sh", "-c", "sleep 3600"]
EOF

kubectl wait --for=condition=Ready pod/monitored-app -n "$QUESTION_ID" --timeout=60s || true

echo "setup.sh: $QUESTION_ID ready (watchdog cannot yet see main-app's process)"
