#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q104-28-multi-container-pod-partial-image-update${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
        - name: proxy
          image: nginx:1.25-alpine
          resources:
            requests: {cpu: 25m, memory: 32Mi}
            limits: {cpu: 50m, memory: 64Mi}
        - name: sidecar-agent
          image: busybox:1.36
          command: ["sleep", "3600"]
          resources:
            requests: {cpu: 25m, memory: 32Mi}
            limits: {cpu: 50m, memory: 64Mi}
EOF
# 2 pods x 2 containers at the namespace's default LimitRange (64Mi
# request/128Mi limit each) already uses 256Mi/512Mi of the 320Mi/640Mi
# quota - leaving no room for the rolling update's surge pod (needs
# another 2-container pod alongside the 2 old ones briefly). Explicit,
# smaller per-container resources here halve that footprint so the surge
# fits.

kubectl rollout status deployment/edge-proxy -n "$QUESTION_ID" --timeout=60s

echo "setup.sh: $QUESTION_ID ready"
