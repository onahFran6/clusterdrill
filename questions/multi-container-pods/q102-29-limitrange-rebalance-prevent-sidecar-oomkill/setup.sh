#!/usr/bin/env bash
# Idempotent: creates/resets namespace
# q102-29-limitrange-rebalance-prevent-sidecar-oomkill, seeds a namespace
# LimitRange capping each container's own memory limit at 128Mi, and a
# BROKEN two-container "batch-processor" Pod:
#
#   - "main" needs to hold a real ~86Mi in-memory buffer (built via a
#     single `awk sprintf` call so the buffer lives in the container's own
#     PID 1 process, not a short-lived child - see the empirical note
#     below) but its own memory limit is set to only 24Mi, so the kubelet
#     OOMKills it every time it tries to do its real work.
#   - "metrics-sidecar" only ever needs a few Mi (it appends one heartbeat
#     line every 15s) but was needlessly provisioned with a 112Mi memory
#     limit, hoarding headroom right up against the namespace's 128Mi
#     per-container LimitRange ceiling.
#
# Empirical note on the OOM technique (verified live against this cluster
# before picking it): a subprocess-based memory hog (e.g. `dd` piped
# through `tr`, or `dd` run as a child of `sh -c "dd ...; sleep ..."`) is
# NOT reliable here - the kernel OOM killer can kill just the oversized
# CHILD process while the container's own PID 1 (the wrapping shell)
# survives untouched, so kubelet never records a container-level
# OOMKilled/restart at all. Likewise, doubling a string's length in a loop
# (`s = s s`) overshoots the target by up to ~2x on its last iteration
# (both the old and new buffers briefly coexist), which OOMKills even a
# generously-sized container. `awk`'s BEGIN block running
# `sprintf("%-Ns","")` allocates exactly N bytes in ONE call, entirely
# within awk's own process (which IS the container's PID 1 here) - the
# only technique of the ones tried that reliably OOMKills at a too-low
# limit and reliably does NOT at a right-sized one.
set -euo pipefail

QUESTION_ID="q102-29-limitrange-rebalance-prevent-sidecar-oomkill${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

# This question's own LimitRange: a 128Mi per-container memory-limit
# ceiling, layered on top of the mandatory clusterdrill-default-limits
# LimitRange (default/defaultRequest only - no max) that
# apply_default_resource_limits already applied above. Both containers
# below set every resources field explicitly, so neither LimitRange's
# defaulting behavior ever kicks in - only this one's "max" matters here.
kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: v1
kind: LimitRange
metadata:
  name: container-mem-ceiling
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  limits:
    - type: Container
      max:
        memory: 128Mi
EOF

# --- The broken Pod --------------------------------------------------------
kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: batch-processor
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  containers:
    - name: main
      image: busybox:1.36
      command:
        - awk
        - BEGIN{s=sprintf("%-90000000s",""); print length(s); system("sleep 3600")}
      resources:
        requests:
          cpu: 25m
          memory: 24Mi
        limits:
          cpu: 100m
          memory: 24Mi
    - name: metrics-sidecar
      image: busybox:1.36
      command: ["sh", "-c", "while true; do echo heartbeat >> /tmp/metrics.log; sleep 15; done"]
      resources:
        requests:
          cpu: 25m
          memory: 8Mi
        limits:
          cpu: 50m
          memory: 112Mi
EOF

echo "setup.sh: $QUESTION_ID ready"
