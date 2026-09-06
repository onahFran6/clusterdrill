#!/usr/bin/env bash
# Idempotent: creates/resets namespace q101-25-rightsize-deployment-via-set-resources,
# a LimitRange enforcing a minimum container request of cpu=100m/memory=64Mi, and a
# Deployment 'lean-api' whose container requests only cpu=50m/memory=32Mi - below that
# floor - so every pod template the ReplicaSet tries to create is rejected at admission
# and the Deployment sits at zero available/ready replicas with FailedCreate events.
# Every cluster object created here carries the label
# clusterdrill-question=q101-25-rightsize-deployment-via-set-resources
#.

set -euo pipefail

QUESTION_ID="q101-25-rightsize-deployment-via-set-resources${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

# Namespace-specific LimitRange: a minimum per-container request, layered on
# top of apply_default_resource_limits' own default/defaultRequest LimitRange
# (multiple LimitRange objects in one namespace are additive - admission must
# satisfy all of them). This is the constraint the candidate has to diagnose
# and satisfy.
kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: v1
kind: LimitRange
metadata:
  name: min-container-requests
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  limits:
    - type: Container
      min:
        cpu: "100m"
        memory: "64Mi"
EOF

# Deployment whose container requests fall below the LimitRange minimum -
# every pod template is rejected at admission, so the ReplicaSet can never
# create a pod and the Deployment sits at zero available/ready replicas.
kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: lean-api
  labels:
    app: lean-api
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 2
  selector:
    matchLabels:
      app: lean-api
  template:
    metadata:
      labels:
        app: lean-api
    spec:
      containers:
        - name: lean-api
          image: nginx:1.25-alpine
          resources:
            requests:
              cpu: "50m"
              memory: "32Mi"
            limits:
              cpu: "100m"
              memory: "64Mi"
EOF

# Give the controller a moment to attempt (and fail) pod creation so
# describe/events already show FailedCreate for the candidate to diagnose,
# but don't hang setup.sh waiting on replicas that will never come up.
kubectl wait --for=condition=Available deployment/lean-api -n "$QUESTION_ID" --timeout=15s || true

echo "setup.sh: $QUESTION_ID ready"
