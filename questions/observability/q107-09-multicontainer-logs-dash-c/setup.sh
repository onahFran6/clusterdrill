#!/usr/bin/env bash
# Idempotent: creates/resets namespace and seeds a two-container pod where
# only the 'consumer' container prints a distinguishing token to stdout.
set -euo pipefail

QUESTION_ID="q107-09-multicontainer-logs-dash-c${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

# Deterministic-but-not-obvious token derived from the namespace, so the
# check can recompute the expected value without storing it in the cluster
# in a way the candidate could read some other way.
TOKEN="$(echo -n "$QUESTION_ID" | md5sum | cut -c1-12)"

kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: order-pipeline
  labels:
    app: order-pipeline
    clusterdrill-question: $QUESTION_ID
spec:
  containers:
    - name: producer
      image: busybox:1.36
      command: ["sh", "-c", "echo 'producer starting, no token here'; sleep 3600"]
    - name: consumer
      image: busybox:1.36
      command: ["sh", "-c", "echo CONSUMER_TOKEN=$TOKEN; sleep 3600"]
EOF

kubectl wait --for=condition=Ready pod/order-pipeline -n "$QUESTION_ID" --timeout=60s || true

echo "setup.sh: $QUESTION_ID ready"
