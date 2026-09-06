#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q104-43-multi-container-both-images-single-rollout${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: edge-proxy
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 2
  selector:
    matchLabels:
      app: edge-proxy
  template:
    metadata:
      labels:
        app: edge-proxy
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        # Explicit, small resources on both containers: a default rolling
        # update briefly surges one extra pod (2 containers) alongside the
        # 2 already-running pods - at the LimitRange's default 128Mi/
        # container that's 768Mi of peak limits.memory, over the namespace
        # ResourceQuota's 640Mi cap, so the new pod can never be admitted.
        - name: proxy
          image: nginx:1.24-alpine
          resources:
            requests:
              cpu: 10m
              memory: 16Mi
            limits:
              cpu: 50m
              memory: 32Mi
        - name: sidecar-logger
          image: busybox:1.35
          command: ["sleep", "3600"]
          resources:
            requests:
              cpu: 10m
              memory: 16Mi
            limits:
              cpu: 50m
              memory: 32Mi
EOF

kubectl rollout status deployment/edge-proxy -n "$QUESTION_ID" --timeout=60s || true

echo "setup.sh: $QUESTION_ID ready (edge-proxy at 2/2 ready replicas)"
