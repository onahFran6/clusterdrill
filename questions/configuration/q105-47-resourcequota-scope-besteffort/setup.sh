#!/usr/bin/env bash
# Idempotent: creates/resets namespace
# q105-47-resourcequota-scope-besteffort with a BestEffort-scoped
# ResourceQuota, a pre-existing BestEffort pod already consuming its one
# slot, and ~/extra-pod.yaml on disk for the candidate to fix.
#
# NOTE: apply_default_resource_limits is deliberately NOT called here - it
# would inject a namespace-wide LimitRange that auto-fills cpu/memory
# defaultRequest/default on every pod that doesn't set its own, meaning no
# pod in this namespace could ever actually be BestEffort (the whole
# premise this question tests). Mirrors q105-12/q105-21/q105-27/q105-42,
# which skip it for the same reason: their own ResourceQuota/LimitRange
# behavior is the thing under test.

set -euo pipefail

QUESTION_ID="q105-47-resourcequota-scope-besteffort${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: besteffort-quota
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  scopes:
    - BestEffort
  hard:
    pods: "1"
EOF

kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: existing-besteffort
  labels:
    app: existing-besteffort
    clusterdrill-question: $QUESTION_ID
spec:
  containers:
    - name: existing-besteffort
      image: busybox:1.36
      command: ["sleep", "3600"]
EOF

kubectl wait --for=condition=Ready pod/existing-besteffort -n "$QUESTION_ID" --timeout=60s || true

WORK_DIR="$(question_workdir "$QUESTION_ID")"
cat > "$WORK_DIR/extra-pod.yaml" <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: extra-worker
spec:
  containers:
    - name: extra-worker
      image: busybox:1.36
      command: ["sleep", "3600"]
EOF

echo "setup.sh: $QUESTION_ID ready"
