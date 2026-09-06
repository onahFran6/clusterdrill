#!/usr/bin/env bash
# Idempotent: creates/resets namespace
# q105-42-resourcequota-requires-explicit-resources with a ResourceQuota
# 'strict-quota' and a ~/worker.yaml manifest missing resources.
#
# NOTE: this question's own ResourceQuota is part of the scenario under
# test (a pod without explicit resources must be rejected by it), so
# apply_default_resource_limits is deliberately NOT called here - it would
# add a namespace-wide LimitRange that auto-fills defaults for any pod
# missing resources, silently defeating the whole point of this question
# before the candidate does anything. Mirrors q105-12-limitrange-defaults /
# q105-27-resourcequota-blocks-new-pod, which skip it for the same reason.

set -euo pipefail

QUESTION_ID="q105-42-resourcequota-requires-explicit-resources${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: v1
kind: ResourceQuota
metadata:
  name: strict-quota
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  hard:
    requests.cpu: "1"
    requests.memory: "1Gi"
    limits.cpu: "2"
    limits.memory: "2Gi"
    pods: "5"
EOF

WORK_DIR="$(question_workdir "$QUESTION_ID")"
cat > "$WORK_DIR/worker.yaml" <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: worker
spec:
  containers:
    - name: worker
      image: busybox:1.36
      command: ["sleep", "3600"]
EOF

echo "setup.sh: $QUESTION_ID ready"
