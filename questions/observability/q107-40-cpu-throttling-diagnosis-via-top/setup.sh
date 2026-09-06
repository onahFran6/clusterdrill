#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q107-40-cpu-throttling-diagnosis-via-top${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

# cpu limit (10m) is far too low for even a trivial busy loop - the
# container itself stays Running (this is throttling, not an OOM kill or
# crash), but kubectl top shows usage pegged flat at the 10m ceiling no
# matter how much real work the loop tries to do.
kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: number-cruncher
  labels:
    app: number-cruncher
    clusterdrill-question: $QUESTION_ID
spec:
  containers:
    - name: number-cruncher
      image: busybox:1.36
      command: ["sh", "-c", "i=0; while true; do i=\$((i+1)); done"]
      resources:
        requests:
          cpu: 10m
          memory: 16Mi
        limits:
          cpu: 10m
          memory: 32Mi
EOF

kubectl wait --for=condition=Ready pod/number-cruncher -n "$QUESTION_ID" --timeout=60s || true

echo "setup.sh: $QUESTION_ID ready (number-cruncher severely CPU-throttled at a 10m limit)"
