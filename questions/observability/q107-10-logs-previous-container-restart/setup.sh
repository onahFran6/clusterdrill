#!/usr/bin/env bash
# Idempotent: creates/resets namespace and seeds a pod whose container
# crashes exactly once (printing a marker line) then restarts and stays
# Running - the marker is only visible via `kubectl logs --previous`.
set -euo pipefail

QUESTION_ID="q107-10-logs-previous-container-restart${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

# Deterministic-but-not-obvious code derived from the namespace, so check.sh
# can recompute the expected value independently.
CODE="$(echo -n "$QUESTION_ID" | sha1sum | cut -c1-10)"

kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: flaky-init
  labels:
    app: flaky-init
    clusterdrill-question: $QUESTION_ID
spec:
  restartPolicy: Always
  containers:
    - name: flaky-init
      image: busybox:1.36
      command: ["sh", "-c", "test -f /data/ran && (echo recovered; sleep 3600) || (echo INIT_FAILURE_CODE=$CODE; touch /data/ran; exit 1)"]
      volumeMounts:
        - name: state
          mountPath: /data
  volumes:
    - name: state
      emptyDir: {}
EOF

# Wait for the first crash-and-restart cycle to complete so the previous
# container instance's logs are actually available to read.
for _ in $(seq 1 20); do
  restarts="$(kubectl get pod flaky-init -n "$QUESTION_ID" -o jsonpath='{.status.containerStatuses[0].restartCount}' 2>/dev/null || true)"
  [ "$restarts" = "1" ] && break
  sleep 3
done
kubectl wait --for=condition=Ready pod/flaky-init -n "$QUESTION_ID" --timeout=60s || true

echo "setup.sh: $QUESTION_ID ready"
