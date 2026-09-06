#!/usr/bin/env bash
# Idempotent: creates/resets namespace and seeds a pod whose memory limit is
# far below what its workload needs, guaranteeing OOMKilled/CrashLoopBackOff.
set -euo pipefail

QUESTION_ID="q107-08-diagnose-crashloop-oomkilled${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: render-worker
  labels:
    app: render-worker
    clusterdrill-question: $QUESTION_ID
spec:
  containers:
    - name: render-worker
      image: polinux/stress
      command: ["stress"]
      args: ["--vm", "1", "--vm-bytes", "150M", "--vm-hang", "1"]
      resources:
        limits:
          memory: "20Mi"
        requests:
          memory: "20Mi"
EOF

echo "setup.sh: $QUESTION_ID ready (pod will be OOMKilled and enter CrashLoopBackOff)"
