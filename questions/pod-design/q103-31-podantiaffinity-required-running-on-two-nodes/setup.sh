#!/usr/bin/env bash
# Idempotent: creates/resets namespace
# q103-31-podantiaffinity-required-running-on-two-nodes and seeds two plain
# pods, both labeled app=cache-replica, both Running, with NO anti-affinity
# rule between them - the scheduler is free to co-locate them on the same
# node, which is exactly the availability gap the candidate has to close.
#
# This question genuinely needs a cluster with >= 2 nodes to be solvable at
# all: the fix is a *required* podAntiAffinity rule, and a required rule on
# a single-node cluster leaves the recreated pod Pending forever (see the
# companion question q103-26, which demonstrates exactly that failure mode
# on purpose). requirements.min_nodes: 2 in this topic's domains.fragment.yaml
# is what keeps this question off a one-node appliance - see
# web/questions.py's Question.is_eligible_for().
#
# Both pods request/limit small explicit resources so two pods in this one
# namespace stay well under the shared default ResourceQuota (600m cpu /
# 320Mi mem requests).

set -euo pipefail

QUESTION_ID="q103-31-podantiaffinity-required-running-on-two-nodes${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: cache-0
  labels:
    app: cache-replica
    clusterdrill-question: $QUESTION_ID
spec:
  containers:
    - name: cache
      image: busybox:1.36
      command: ["sleep", "3600"]
      resources:
        requests:
          cpu: 25m
          memory: 32Mi
        limits:
          cpu: 50m
          memory: 64Mi
EOF

kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: cache-1
  labels:
    app: cache-replica
    clusterdrill-question: $QUESTION_ID
spec:
  containers:
    - name: cache
      image: busybox:1.36
      command: ["sleep", "3600"]
      resources:
        requests:
          cpu: 25m
          memory: 32Mi
        limits:
          cpu: 50m
          memory: 64Mi
EOF

kubectl wait --for=condition=Ready pod/cache-0 -n "$QUESTION_ID" --timeout=60s >/dev/null 2>&1 || true
kubectl wait --for=condition=Ready pod/cache-1 -n "$QUESTION_ID" --timeout=60s >/dev/null 2>&1 || true

echo "setup.sh: $QUESTION_ID ready (cache-0 and cache-1 both Running, no anti-affinity yet)"
