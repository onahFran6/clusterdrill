#!/usr/bin/env bash
# Idempotent: creates/resets namespace q106-32-seccomp-runtime-default and
# seeds a single running pod whose container has no securityContext at all -
# it runs "unconfined", inheriting whatever the container runtime's default
# seccomp posture happens to be, instead of explicitly opting into the
# RuntimeDefault seccomp profile. Every cluster object created here carries
# the label clusterdrill-question=q106-32-seccomp-runtime-default
#.

set -euo pipefail

QUESTION_ID="q106-32-seccomp-runtime-default${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: worker
  labels:
    app: worker
    clusterdrill-question: $QUESTION_ID
spec:
  containers:
    - name: worker
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

kubectl wait --for=condition=Ready pod/worker -n "$QUESTION_ID" --timeout=60s >/dev/null 2>&1 || true

echo "setup.sh: $QUESTION_ID ready"
