#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q104-31-fix-canary-selector-leak-wrong-traffic-split${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

# Small explicit per-container resources throughout: up to 6 pods across
# the three Deployments below would otherwise hit the namespace's default
# ResourceQuota under the LimitRange's default per-container request/limit.
kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: recs-svc
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  selector:
    app: recs
  ports:
    - port: 80
      targetPort: 80
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: recs-stable
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 3
  selector:
    matchLabels:
      app: recs
      tier: stable
  template:
    metadata:
      labels:
        app: recs
        tier: stable
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: recs
          image: nginx:1.25-alpine
          resources:
            requests: {cpu: 25m, memory: 32Mi}
            limits: {cpu: 50m, memory: 64Mi}
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: recs-canary
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 1
  selector:
    matchLabels:
      app: recs
      tier: canary
  template:
    metadata:
      labels:
        app: recs
        tier: canary
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: recs
          image: nginx:1.25-alpine
          resources:
            requests: {cpu: 25m, memory: 32Mi}
            limits: {cpu: 50m, memory: 64Mi}
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: recs-debug-leftover
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 2
  selector:
    matchLabels:
      app: recs
      debug: "true"
  template:
    metadata:
      labels:
        app: recs
        debug: "true"
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: recs
          image: nginx:1.25-alpine
          resources:
            requests: {cpu: 25m, memory: 32Mi}
            limits: {cpu: 50m, memory: 64Mi}
EOF

kubectl rollout status deployment/recs-stable -n "$QUESTION_ID" --timeout=60s
kubectl rollout status deployment/recs-canary -n "$QUESTION_ID" --timeout=60s
kubectl rollout status deployment/recs-debug-leftover -n "$QUESTION_ID" --timeout=60s

echo "setup.sh: $QUESTION_ID ready"
