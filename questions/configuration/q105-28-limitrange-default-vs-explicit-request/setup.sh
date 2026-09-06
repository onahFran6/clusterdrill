#!/usr/bin/env bash
# Idempotent: creates/resets namespace q105-28-limitrange-default-vs-explicit-request,
# seeds a LimitRange capping container memory limit at 256Mi (default request
# 128Mi), and drops an unapplied bigmem.yaml (memory limit 512Mi, no request)
# into the candidate's terminal working directory for them to fix and apply.
#
# Deliberately does NOT call apply_default_resource_limits here (like
# q105-12-limitrange-defaults and q105-21-limitrange-min-max-bounds): this
# question is itself about how a namespace's own LimitRange resolves an
# unset request against an explicit over-limit value, and the mandatory
# clusterdrill-default-limits LimitRange (also type: Container, also
# setting default/defaultRequest.memory) would compete with it in the same
# namespace and change which values actually land on the pod.

set -euo pipefail

QUESTION_ID="q105-28-limitrange-default-vs-explicit-request${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: container-limits
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  limits:
    - type: Container
      max:
        memory: "256Mi"
      defaultRequest:
        memory: "128Mi"
EOF

# Unapplied manifest for the candidate to fix - memory limit of 512Mi
# exceeds the LimitRange's 256Mi max, so applying it as-is is rejected by
# admission. Not graded directly (check.sh only looks at live cluster
# state); the candidate must edit this file and re-apply it.
WORK_DIR="$(question_workdir "$QUESTION_ID")"
cat > "$WORK_DIR/bigmem.yaml" <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: bigmem
spec:
  containers:
    - name: bigmem
      image: nginx:1.25-alpine
      resources:
        limits:
          memory: 512Mi
EOF

echo "setup.sh: $QUESTION_ID ready"
