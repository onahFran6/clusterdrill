#!/usr/bin/env bash
# Idempotent: creates/resets namespace and applies a Pod with a nodeSelector
# no node in this cluster actually has, so it stays Pending forever. This
# deliberately never touches the real Node object (labeling/tainting the
# shared cluster node would affect every other question running
# concurrently and isn't cleaned up by full_reset) - the fix is entirely
# on the Pod side.

set -euo pipefail

QUESTION_ID="q107-42-nodeselector-mismatch-blocks-scheduling${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: report-worker
  labels:
    app: report-worker
    clusterdrill-question: $QUESTION_ID
spec:
  nodeSelector:
    disktype: ssd
  containers:
    - name: report-worker
      image: nginx:1.25-alpine
EOF

sleep 5

echo "setup.sh: $QUESTION_ID ready (report-worker stuck Pending - no node in this cluster is labeled disktype=ssd)"
