#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q111-19-pending-nodeselector-and-cpu${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

# Node labels are cluster-scoped and NOT covered by full_reset (lib/grading.sh
# only sweeps clusterrole,clusterrolebinding,pv,storageclass,crd by label) -
# nothing else in this engine cleans them up. This question is the only one
# in the bank that mutates a real Node, so it must strip any disktype label
# it (or a previous run of this same question) left behind, every time, or
# repeated runs would leak global cluster state and a second run could find
# a node that's already "fixed" before the candidate does anything.
for node in $(kubectl get nodes -o jsonpath='{.items[*].metadata.name}'); do
  kubectl label node "$node" disktype- >/dev/null 2>&1 || true
done

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
# Deliberately skips apply_default_resource_limits (lib/grading.sh): its
# 600m requests.cpu ResourceQuota would reject the 3rd of 3 pods at
# admission once all three legitimately request 250m (750m total), turning
# the intended scheduling lesson into a quota-exceeded fault instead. Same
# precedent as q105-12-limitrange-defaults/q105-21-limitrange-min-max-bounds
# skipping it for a competing-LimitRange reason.
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: press
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 3
  selector:
    matchLabels:
      app: press
  template:
    metadata:
      labels:
        app: press
        clusterdrill-question: $QUESTION_ID
    spec:
      nodeSelector:
        disktype: ssd
      containers:
        - name: press
          image: nginx:1.27
          resources:
            requests:
              cpu: "64"  # absurdly large on purpose - no node can satisfy this request
EOF

echo "setup.sh: $QUESTION_ID ready"
