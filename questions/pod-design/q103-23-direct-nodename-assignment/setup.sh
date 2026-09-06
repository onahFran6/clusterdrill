#!/usr/bin/env bash
# Idempotent: creates/resets namespace q103-23-direct-nodename-assignment and
# writes an incomplete pod manifest to this question's terminal working
# directory for the candidate to complete and apply. The manifest is never
# applied here - it is missing .spec.nodeName on purpose, so the unsolved
# state has NO pod object at all (not even an unscheduled one), which keeps
# a single-node cluster from making "the pod landed on the right node"
# trivially/accidentally true before the candidate does anything.

set -euo pipefail

QUESTION_ID="q103-23-direct-nodename-assignment${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

WORK_DIR="$(question_workdir "$QUESTION_ID")"
cat > "$WORK_DIR/node-pinned.yaml" <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: node-pinned
  namespace: $QUESTION_ID
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  # TODO: pin this pod directly to this cluster's node by adding a
  # nodeName field here, set to this cluster's actual node name
  # (find it with: kubectl get nodes -o name)
  containers:
    - name: node-pinned
      image: busybox:1.36
      command: ["sleep", "3600"]
EOF

echo "setup.sh: $QUESTION_ID ready (incomplete manifest at $WORK_DIR/node-pinned.yaml, not yet applied)"
