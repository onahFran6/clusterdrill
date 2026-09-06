#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q107-44-terminationgraceperiod-vs-prestop-timing${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

# preStop needs ~8s to drain connections (sleep 8), but
# terminationGracePeriodSeconds is only 2 - the kubelet SIGKILLs the
# container long before preStop can finish, on every termination. The
# candidate must widen the grace period, not shorten the drain.
kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: connection-drainer
  labels:
    app: connection-drainer
    clusterdrill-question: $QUESTION_ID
spec:
  terminationGracePeriodSeconds: 2
  containers:
    - name: connection-drainer
      image: nginx:1.25-alpine
      lifecycle:
        preStop:
          exec:
            command: ["sh", "-c", "sleep 8"]
EOF

kubectl wait --for=condition=Ready pod/connection-drainer -n "$QUESTION_ID" --timeout=60s || true

echo "setup.sh: $QUESTION_ID ready"
