#!/usr/bin/env bash
# Idempotent: creates/resets namespace q102-38-readiness-probe-wrong-container-port
# and seeds a BROKEN Pod. "web" (nginx, actually listening fine on 80) has a
# readinessProbe that targets port 9000 instead of 80 - a copy-paste leftover
# from an old sidecar port that no longer applies. Nothing in the Pod
# listens on 9000 at all (every container in a Pod shares one network
# namespace/IP, so a probe's port is checked against the Pod as a whole, not
# scoped to "this container's own process" - but that doesn't help here
# since nothing anywhere in the Pod is bound to 9000), so the probe never
# succeeds even though nginx itself is completely healthy: kubectl get pod
# shows 1/2, "web" stuck Running-but-NotReady. "sidecar-metrics" is an
# unrelated second container that is not part of the bug.
set -euo pipefail

QUESTION_ID="q102-38-readiness-probe-wrong-container-port${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: probe-mixup
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  containers:
    - name: web
      image: nginx:1.27-alpine
      ports:
        - containerPort: 80
      readinessProbe:
        tcpSocket:
          port: 9000
        periodSeconds: 3
        failureThreshold: 2
      resources:
        requests:
          cpu: 25m
          memory: 32Mi
        limits:
          cpu: 50m
          memory: 64Mi
    - name: sidecar-metrics
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
