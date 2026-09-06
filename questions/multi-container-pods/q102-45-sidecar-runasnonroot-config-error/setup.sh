#!/usr/bin/env bash
# Idempotent: creates/resets namespace q102-45-sidecar-runasnonroot-config-error
# and seeds a BROKEN Pod. Pod-level securityContext sets runAsNonRoot: true
# (a real, common hardening baseline). "app" explicitly sets its own
# securityContext.runAsUser: 1000, so it's fine. "sidecar" has NO container-
# level securityContext.runAsUser at all, and busybox:1.36's image defaults
# to running as root (UID 0) - since the effective runAsNonRoot: true is
# still inherited from the Pod, but there is no runAsUser to prove the
# image won't run as root, the kubelet refuses to even create "sidecar":
# it sits waiting with reason CreateContainerConfigError forever. "app" is
# unaffected. kubectl get pod shows 1/2.
set -euo pipefail

QUESTION_ID="q102-45-sidecar-runasnonroot-config-error${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: hardened-app
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  securityContext:
    runAsNonRoot: true
  containers:
    - name: app
      image: busybox:1.36
      command: ["sh", "-c", "while true; do sleep 3600; done"]
      securityContext:
        runAsUser: 1000
      resources:
        requests:
          cpu: 25m
          memory: 32Mi
        limits:
          cpu: 50m
          memory: 64Mi
    - name: sidecar
      image: busybox:1.36
      command: ["sh", "-c", "while true; do sleep 3600; done"]
      resources:
        requests:
          cpu: 25m
          memory: 32Mi
        limits:
          cpu: 50m
          memory: 64Mi
EOF

echo "setup.sh: $QUESTION_ID ready"
