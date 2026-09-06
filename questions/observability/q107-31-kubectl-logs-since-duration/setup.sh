#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q107-31-kubectl-logs-since-duration${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: heartbeat
  labels:
    app: heartbeat
    clusterdrill-question: $QUESTION_ID
spec:
  containers:
    - name: heartbeat
      image: busybox:1.36
      command: ["sh", "-c", "echo old-line-before-cutoff; sleep 5; while true; do echo recent-heartbeat; sleep 2; done"]
EOF

kubectl wait --for=condition=Ready pod/heartbeat -n "$QUESTION_ID" --timeout=60s || true
# Let the old line age well past the --since window the candidate will use,
# and a couple of recent ones accumulate.
sleep 10

echo "setup.sh: $QUESTION_ID ready"
