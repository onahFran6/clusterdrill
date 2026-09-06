#!/usr/bin/env bash
# Idempotent: creates/resets namespace
# q103-49-combined-fieldselector-setbased-labelselector-delete and seeds five pods: three
# one-shot pods that already ran to Succeeded (env=staging/prod/dev) and two still-Running pods
# (env=staging/canary), so the correct delete command must combine both a field selector (phase)
# and a set-based label selector (env) to hit exactly the right two.

set -euo pipefail

QUESTION_ID="q103-49-combined-fieldselector-setbased-labelselector-delete${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

for pair in "stale-1:staging" "stale-2:prod" "stale-3:dev"; do
  name="${pair%%:*}"
  env="${pair##*:}"
  kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: $name
  labels:
    clusterdrill-question: $QUESTION_ID
    env: $env
spec:
  restartPolicy: Never
  containers:
    - name: $name
      image: busybox:1.36
      command: ["echo", "done"]
      resources:
        requests: {cpu: 25m, memory: 32Mi}
        limits: {cpu: 50m, memory: 64Mi}
EOF
done

for pair in "active-1:staging" "active-2:canary"; do
  name="${pair%%:*}"
  env="${pair##*:}"
  kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: $name
  labels:
    clusterdrill-question: $QUESTION_ID
    env: $env
spec:
  containers:
    - name: $name
      image: busybox:1.36
      command: ["sleep", "3600"]
      resources:
        requests: {cpu: 25m, memory: 32Mi}
        limits: {cpu: 50m, memory: 64Mi}
EOF
done

for p in stale-1 stale-2 stale-3; do
  kubectl wait --for=jsonpath='{.status.phase}'=Succeeded "pod/$p" -n "$QUESTION_ID" --timeout=60s || true
done
kubectl wait --for=condition=Ready pod/active-1 pod/active-2 -n "$QUESTION_ID" --timeout=60s || true

echo "setup.sh: $QUESTION_ID ready"
