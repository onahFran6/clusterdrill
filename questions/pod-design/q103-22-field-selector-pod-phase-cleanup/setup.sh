#!/usr/bin/env bash
# Idempotent: creates/resets namespace and seeds two Running pods plus three
# one-shot pods that must actually reach phase Succeeded before handing
# control to the candidate (see the wait loop below).
set -euo pipefail

QUESTION_ID="q103-22-field-selector-pod-phase-cleanup${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

# Two long-running application pods - must stay Running and untouched by
# the candidate's cleanup command.
for name in worker-1 worker-2; do
  kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: $name
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  containers:
    - name: $name
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
done

# Three one-shot debug pods that already ran to completion. restartPolicy
# Never means a finished container is never restarted, so the pod's phase
# settles at Succeeded instead of cycling back through Running.
for name in debug-1 debug-2 debug-3; do
  kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: $name
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  restartPolicy: Never
  containers:
    - name: $name
      image: busybox:1.36
      command: ["sh", "-c", "echo done && exit 0"]
      resources:
        requests:
          cpu: 25m
          memory: 32Mi
        limits:
          cpu: 50m
          memory: 64Mi
EOF
done

# Wait for the debug pods to actually settle in phase Succeeded before
# returning control. Without this, check.sh's unsolved-state grading could
# race a still-Pending/Running debug pod and read "0 Succeeded pods" as if
# the candidate had already cleaned up, giving a false non-zero score on
# the unsolved state.
for name in debug-1 debug-2 debug-3; do
  phase=""
  for _ in $(seq 1 30); do
    phase="$(kubectl get pod "$name" -n "$QUESTION_ID" -o jsonpath='{.status.phase}' 2>/dev/null || true)"
    [ "$phase" = "Succeeded" ] && break
    sleep 2
  done
  if [ "$phase" != "Succeeded" ]; then
    echo "setup.sh: WARNING - $name did not reach Succeeded (phase=$phase)" >&2
  fi
done

echo "setup.sh: $QUESTION_ID ready"
