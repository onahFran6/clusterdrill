#!/usr/bin/env bash
# Idempotent: creates/resets namespace q103-37-combined-fieldselector-labelselector-bulk-label and
# seeds four pods: two Running tier=batch pods, one deliberately Pending tier=batch pod (impossible
# nodeSelector), and one Running tier=web distractor pod.

set -euo pipefail

QUESTION_ID="q103-37-combined-fieldselector-labelselector-bulk-label${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: batch-ok-1
  labels:
    clusterdrill-question: $QUESTION_ID
    tier: batch
spec:
  containers:
    - name: batch-ok-1
      image: busybox:1.36
      command: ["sleep", "3600"]
      resources:
        requests: {cpu: 25m, memory: 32Mi}
        limits: {cpu: 50m, memory: 64Mi}
---
apiVersion: v1
kind: Pod
metadata:
  name: batch-ok-2
  labels:
    clusterdrill-question: $QUESTION_ID
    tier: batch
spec:
  containers:
    - name: batch-ok-2
      image: busybox:1.36
      command: ["sleep", "3600"]
      resources:
        requests: {cpu: 25m, memory: 32Mi}
        limits: {cpu: 50m, memory: 64Mi}
---
apiVersion: v1
kind: Pod
metadata:
  name: batch-broken
  labels:
    clusterdrill-question: $QUESTION_ID
    tier: batch
spec:
  nodeSelector:
    disktype: ssd-that-does-not-exist
  containers:
    - name: batch-broken
      image: busybox:1.36
      command: ["sleep", "3600"]
      resources:
        requests: {cpu: 25m, memory: 32Mi}
        limits: {cpu: 50m, memory: 64Mi}
---
apiVersion: v1
kind: Pod
metadata:
  name: web-1
  labels:
    clusterdrill-question: $QUESTION_ID
    tier: web
spec:
  containers:
    - name: web-1
      image: busybox:1.36
      command: ["sleep", "3600"]
      resources:
        requests: {cpu: 25m, memory: 32Mi}
        limits: {cpu: 50m, memory: 64Mi}
EOF

kubectl wait --for=condition=Ready pod/batch-ok-1 pod/batch-ok-2 pod/web-1 -n "$QUESTION_ID" --timeout=60s || true

echo "setup.sh: $QUESTION_ID ready"
