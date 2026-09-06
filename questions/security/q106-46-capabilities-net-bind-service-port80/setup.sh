#!/usr/bin/env bash
# Idempotent: creates/resets namespace and attempts to run a non-root
# listener on port 80 (a privileged port on Linux - binding it as non-root
# needs CAP_NET_BIND_SERVICE, which this Pod does not have). busybox's `nc`
# exits immediately with "permission denied", so the container crash-loops.
# This apply itself succeeds (the Pod object is created); it's the running
# container that's broken - do not let that abort setup.sh.

set -uo pipefail

QUESTION_ID="q106-46-capabilities-net-bind-service-port80${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f - || {
  echo "setup.sh: failed to create/apply namespace $QUESTION_ID" >&2
  exit 1
}
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: privileged-port-listener
  labels:
    app: privileged-port-listener
    clusterdrill-question: $QUESTION_ID
spec:
  securityContext:
    runAsUser: 1000
    runAsNonRoot: true
  containers:
    - name: listener
      image: busybox:1.36
      command: ["sh", "-c", "while true; do nc -l -p 80 -e echo ok; done"]
      securityContext:
        capabilities:
          drop: ["ALL"]
      readinessProbe:
        tcpSocket:
          port: 80
        periodSeconds: 2
        failureThreshold: 1
      resources:
        requests:
          cpu: 25m
          memory: 32Mi
        limits:
          cpu: 50m
          memory: 64Mi
EOF

echo "setup.sh: $QUESTION_ID ready (privileged-port-listener will crash-loop until the candidate fixes it)"
