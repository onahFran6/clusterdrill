#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q107-24-readiness-gate-blocks-deployment-rollout${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

# Generation 1: a healthy Deployment, 3 replicas, working readiness probe.
kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: checkout-api
  labels:
    app: checkout-api
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1
      maxSurge: 1
  selector:
    matchLabels:
      app: checkout-api
  template:
    metadata:
      labels:
        app: checkout-api
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: nginx
          image: nginx:1.25-alpine
          ports:
            - containerPort: 80
          readinessProbe:
            httpGet:
              path: /
              port: 80
            initialDelaySeconds: 2
            periodSeconds: 3
EOF
kubectl rollout status deployment/checkout-api -n "$QUESTION_ID" --timeout=60s

# Generation 2: a bad rollout - typo'd tag that can never be pulled. New
# ReplicaSet's pod(s) sit in ImagePullBackOff/ErrImagePull forever, so the
# rolling update can only ever bring down at most maxUnavailable=1 of the 3
# healthy generation-1 pods, leaving UP-TO-DATE < 3 and rollout status
# hanging - exactly the stuck state the candidate must diagnose and fix.
kubectl set image deployment/checkout-api nginx=nginx:1.25-alpne -n "$QUESTION_ID"

# Give the rollout controller a moment to create the new ReplicaSet/pod so
# the candidate finds the stuck state (not an empty rollout) immediately.
kubectl rollout status deployment/checkout-api -n "$QUESTION_ID" --timeout=20s || true

echo "setup.sh: $QUESTION_ID ready"
