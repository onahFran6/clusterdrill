#!/usr/bin/env bash
# Idempotent: creates/resets namespace q107-21-prestop-graceful-shutdown-log
# and seeds a running pod that ignores SIGTERM and has no lifecycle hook.
set -euo pipefail

QUESTION_ID="q107-21-prestop-graceful-shutdown-log${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

# lifecycle/terminationGracePeriodSeconds are immutable on a running pod, so
# a stale pod left over from a prior solve attempt (with the candidate's
# preStop hook already set) cannot be reconciled in place by `kubectl
# apply` - always delete first so setup.sh is safe to re-run.
kubectl delete pod session-worker -n "$QUESTION_ID" --ignore-not-found --wait=true

kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: session-worker
  labels:
    app: session-worker
    clusterdrill-question: $QUESTION_ID
spec:
  containers:
    - name: session-worker
      image: busybox:1.36
      command: ["sh", "-c", "trap : TERM; while true; do sleep 1; done"]
EOF

kubectl wait --for=condition=Ready pod/session-worker -n "$QUESTION_ID" --timeout=60s || true

echo "setup.sh: $QUESTION_ID ready"
