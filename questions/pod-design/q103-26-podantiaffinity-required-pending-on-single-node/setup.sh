#!/usr/bin/env bash
# Idempotent: creates/resets namespace q103-26-podantiaffinity-required-pending-on-single-node
# and seeds two pods, both labeled app=cache-replica:
#   - cache-0: a plain pod, no affinity rules - schedules and reaches Running normally.
#   - cache-1: declares a HARD (requiredDuringSchedulingIgnoredDuringExecution) podAntiAffinity
#     rule refusing to co-locate with any app=cache-replica pod on the same node
#     (topologyKey kubernetes.io/hostname). On this cluster's single node, cache-0 already
#     satisfies that "occupied" condition, so cache-1 is unschedulable and sits Pending by
#     design - this is real scheduler behavior, not a seeded bug to patch around.
#
# Both pods request/limit small explicit resources so two pods in this one namespace stay
# well under the shared default ResourceQuota (600m cpu / 320Mi mem requests).

set -euo pipefail

QUESTION_ID="q103-26-podantiaffinity-required-pending-on-single-node${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  affinity:
    podAntiAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        - labelSelector:
            matchLabels:
              app: cache-replica
          topologyKey: kubernetes.io/hostname
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

# Only wait on cache-0 - cache-1 is expected to stay Pending forever until the
# candidate relaxes its anti-affinity rule, so waiting on it here would just
# stall setup.sh for no reason.
kubectl wait --for=condition=Ready pod/cache-0 -n "$QUESTION_ID" --timeout=60s >/dev/null 2>&1 || true

echo "setup.sh: $QUESTION_ID ready (cache-0 Running, cache-1 Pending by design - single-node hard anti-affinity)"
