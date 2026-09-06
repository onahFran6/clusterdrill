#!/usr/bin/env bash
# Idempotent: creates/resets namespace and applies two independently
# CrashLoopBackOff'd Pods with genuinely different root causes - a typo'd
# executable name (worker-a) and an OOM kill from a too-low memory limit
# (worker-b) - so the candidate must actually diagnose each one instead of
# assuming both share one cause.

set -euo pipefail

QUESTION_ID="q107-49-diagnose-two-simultaneous-crashloops-different-causes${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: worker-a
  labels:
    app: worker-a
    clusterdrill-question: $QUESTION_ID
spec:
  containers:
    - name: worker-a
      image: busybox:1.36
      command: ["sleeep", "3600"]
---
apiVersion: v1
kind: Pod
metadata:
  name: worker-b
  labels:
    app: worker-b
    clusterdrill-question: $QUESTION_ID
spec:
  containers:
    - name: worker-b
      image: polinux/stress
      command: ["stress"]
      args: ["--vm", "1", "--vm-bytes", "150M", "--vm-hang", "1"]
      resources:
        limits:
          memory: "20Mi"
        requests:
          memory: "20Mi"
EOF

sleep 15

echo "setup.sh: $QUESTION_ID ready (worker-a: typo'd executable name; worker-b: OOMKilled from a too-low memory limit - two different causes)"
