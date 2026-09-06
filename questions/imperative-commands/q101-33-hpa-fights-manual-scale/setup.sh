#!/usr/bin/env bash
# Idempotent: creates/resets namespace q101-33-hpa-fights-manual-scale and
# seeds a Deployment ("email-worker") already bound to a
# HorizontalPodAutoscaler with minReplicas=3/maxReplicas=6. The container
# requests almost no CPU (25m) so real CPU usage of a "sleep" process stays
# far below the 50% target - the HPA has no reason to scale above
# minReplicas, so it settles at exactly 3 replicas deterministically,
# without needing metrics-server to ever resolve a live metric value (the
# HPA controller enforces the minReplicas/maxReplicas floor/ceiling before
# it even looks at metrics - confirmed empirically in this cluster).
#
# behavior.scaleUp/scaleDown.stabilizationWindowSeconds are pinned to 0 so
# the HPA reacts to a change (either the "fight back" or the candidate's
# fix) within one sync period instead of remembering up to 5 minutes of
# prior recommendations (the default scaleDown stabilization window) - that
# default would otherwise make the reference fix flap back to 3 after the
# candidate had already reached 1, confirmed empirically in this cluster.

set -euo pipefail

QUESTION_ID="q101-33-hpa-fights-manual-scale${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: email-worker
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 3
  selector:
    matchLabels:
      app: email-worker
  template:
    metadata:
      labels:
        app: email-worker
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: email-worker
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

kubectl rollout status deployment/email-worker -n "$QUESTION_ID" --timeout=60s || true

kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: email-worker
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: email-worker
  minReplicas: 3
  maxReplicas: 6
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 50
  behavior:
    scaleUp:
      stabilizationWindowSeconds: 0
      policies:
        - type: Pods
          value: 4
          periodSeconds: 15
    scaleDown:
      stabilizationWindowSeconds: 0
      policies:
        - type: Pods
          value: 4
          periodSeconds: 15
EOF

echo "setup.sh: $QUESTION_ID ready"
