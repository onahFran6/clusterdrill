#!/usr/bin/env bash
# Idempotent: creates/resets namespace q102-42-qos-guaranteed-mismatched-limits
# and seeds a BROKEN Pod. Both containers set resources, but "cache"'s
# requests are lower than its limits (Burstable-shaped), while "app"'s
# requests equal its limits. A Pod's overall QoS class is only "Guaranteed"
# when EVERY container has requests == limits for both cpu and memory - one
# Burstable-shaped container demotes the WHOLE Pod's .status.qosClass to
# "Burstable", even though nothing crashes and the Pod runs fine.
set -euo pipefail

QUESTION_ID="q102-42-qos-guaranteed-mismatched-limits${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: guaranteed-app
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  containers:
    - name: app
      image: busybox:1.36
      command: ["sh", "-c", "while true; do sleep 3600; done"]
      resources:
        requests:
          cpu: 100m
          memory: 64Mi
        limits:
          cpu: 100m
          memory: 64Mi
    - name: cache
      image: busybox:1.36
      command: ["sh", "-c", "while true; do sleep 3600; done"]
      resources:
        requests:
          cpu: 50m
          memory: 32Mi
        limits:
          cpu: 100m
          memory: 64Mi
EOF

echo "setup.sh: $QUESTION_ID ready"
