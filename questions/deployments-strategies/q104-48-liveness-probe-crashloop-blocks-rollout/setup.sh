#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q104-48-liveness-probe-crashloop-blocks-rollout${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

# Broken from the very first apply: the livenessProbe's initialDelaySeconds
# (0) combined with failureThreshold=1 kills the container before the
# 8-second startup script ever creates /tmp/up, forever.
kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: session-api
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 2
  selector:
    matchLabels:
      app: session-api
  template:
    metadata:
      labels:
        app: session-api
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: session-api
          image: busybox:1.36
          command: ["sh", "-c", "sleep 8 && touch /tmp/up && sleep 3600"]
          livenessProbe:
            exec:
              command: ["cat", "/tmp/up"]
            initialDelaySeconds: 0
            periodSeconds: 2
            failureThreshold: 1
EOF

# Don't wait for rollout status here - it will never succeed on its own.
# Give the kubelet a moment to actually run (and crash-loop) the container
# so the stuck state is visibly established before the candidate connects.
sleep 10

echo "setup.sh: $QUESTION_ID ready (session-api stuck crash-looping on an overly aggressive livenessProbe)"
