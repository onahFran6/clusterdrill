#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q104-14-readiness-gate-stuck-rollout${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: inventory
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 3
  progressDeadlineSeconds: 20
  selector:
    matchLabels:
      app: inventory
  template:
    metadata:
      labels:
        app: inventory
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: inventory
          image: nginx:1.24-alpine
EOF
kubectl rollout status deployment/inventory -n "$QUESTION_ID" --timeout=60s || true

# Roll to a new template whose readiness probe can never succeed, so the
# rollout stalls and progressDeadlineSeconds eventually flips Progressing to
# False - this is the exact signal the candidate has to read out.
kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: inventory
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 3
  progressDeadlineSeconds: 20
  selector:
    matchLabels:
      app: inventory
  template:
    metadata:
      labels:
        app: inventory
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: inventory
          image: nginx:1.25-alpine
          readinessProbe:
            httpGet:
              path: /does-not-exist
              port: 80
            periodSeconds: 2
            failureThreshold: 1
EOF

# Wait past progressDeadlineSeconds so the Progressing condition has time to
# flip to False before the candidate (or verify-question.sh) reads it -
# otherwise this check is flaky on whoever happens to look first.
sleep 30

echo "setup.sh: $QUESTION_ID ready (rollout intentionally stuck)"
