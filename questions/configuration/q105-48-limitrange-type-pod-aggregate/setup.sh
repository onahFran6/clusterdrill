#!/usr/bin/env bash
# Idempotent: creates/resets namespace
# q105-48-limitrange-type-pod-aggregate with a type:Pod LimitRange and
# ~/multi-app.yaml on disk (two containers whose combined limits exceed
# that LimitRange's pod-level max).
#
# NOTE: this question's own LimitRange is the graded object (its type:Pod
# aggregate bound is the whole point), so apply_default_resource_limits is
# deliberately NOT called here - stacking a second, competing LimitRange
# would change which rule actually admits the candidate's pod. Mirrors
# q105-12/q105-21/q105-44, whose own LimitRange is likewise under test.

set -euo pipefail

QUESTION_ID="q105-48-limitrange-type-pod-aggregate${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: v1
kind: LimitRange
metadata:
  name: pod-aggregate-limits
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  limits:
    - type: Pod
      max:
        cpu: "500m"
        memory: "512Mi"
EOF

WORK_DIR="$(question_workdir "$QUESTION_ID")"
cat > "$WORK_DIR/multi-app.yaml" <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: multi-app
spec:
  containers:
    - name: primary
      image: busybox:1.36
      command: ["sleep", "3600"]
      resources:
        requests:
          cpu: "300m"
          memory: "300Mi"
        limits:
          cpu: "300m"
          memory: "300Mi"
    - name: helper
      image: busybox:1.36
      command: ["sleep", "3600"]
      resources:
        requests:
          cpu: "300m"
          memory: "300Mi"
        limits:
          cpu: "300m"
          memory: "300Mi"
EOF

echo "setup.sh: $QUESTION_ID ready"
