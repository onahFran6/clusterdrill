#!/usr/bin/env bash
# Idempotent: creates/resets namespace
# q105-33-multicontainer-limitrange-default-mismatch, seeds a LimitRange
# with default memory limit 128Mi / default memory request 64Mi, and drops
# an unapplied worker.yaml (two containers: 'collector' with no resources
# at all, 'shipper' with an explicit 256Mi memory limit and no request)
# into the candidate's terminal working directory for them to inspect,
# fix, and apply. Nothing is applied to the cluster by setup.sh beyond the
# namespace and the LimitRange - the candidate creates the pod themselves,
# which is also what keeps every check.sh criterion at 0 until they act.
#
# Deliberately does NOT call apply_default_resource_limits here (same
# reasoning as q105-12/q105-21/q105-28): this question is itself about how
# a namespace's own LimitRange resolves an unset request, and the mandatory
# clusterdrill-default-limits LimitRange (also type: Container, also
# setting default/defaultRequest.memory) would compete with it in the same
# namespace and change which values actually land on the pod.

set -euo pipefail

QUESTION_ID="q105-33-multicontainer-limitrange-default-mismatch${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: container-mem-defaults
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  limits:
    - type: Container
      default:
        memory: "128Mi"
      defaultRequest:
        memory: "64Mi"
EOF

# Unapplied manifest for the candidate to inspect, fix, and apply. Not
# graded directly (check.sh only looks at live cluster state) - 'shipper'
# sets an explicit memory limit with no request, which admission will
# default to a request equal to that limit (256Mi), not the LimitRange's
# 64Mi defaultRequest, once the candidate applies it as-is.
WORK_DIR="$(question_workdir "$QUESTION_ID")"
cat > "$WORK_DIR/worker.yaml" <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: worker
  labels:
    app: worker
spec:
  containers:
    - name: collector
      image: busybox:1.36
      command: ["sh", "-c", "sleep 3600"]
    - name: shipper
      image: busybox:1.36
      command: ["sh", "-c", "sleep 3600"]
      resources:
        limits:
          memory: "256Mi"
EOF

echo "setup.sh: $QUESTION_ID ready"
