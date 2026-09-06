#!/usr/bin/env bash
# Idempotent: creates/resets namespace and seeds a pod requesting far more
# memory than any node has, guaranteeing Pending + a FailedScheduling event.
#
# Deliberately does NOT call apply_default_resource_limits: that helper's
# ResourceQuota caps requests.memory/limits.memory at 320Mi/640Mi per
# namespace, which would reject this pod at admission time (a quota
# error) instead of letting it reach the scheduler and produce the
# FailedScheduling/"Insufficient memory" Warning event this question is
# actually about. The fixed pod (64Mi/64Mi) stays comfortably inside what
# that quota would have allowed anyway.
set -euo pipefail

QUESTION_ID="q107-16-events-sort-by-time${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: big-mem
  labels:
    app: big-mem
    clusterdrill-question: $QUESTION_ID
spec:
  containers:
    - name: big-mem
      image: nginx:1.25-alpine
      resources:
        requests:
          memory: "900Gi"
        limits:
          memory: "900Gi"
EOF

echo "setup.sh: $QUESTION_ID ready (pod will stay Pending: Insufficient memory)"
