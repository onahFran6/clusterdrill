#!/usr/bin/env bash
# This question's whole point is the exact bounds of one specific,
# pre-seeded LimitRange. Deliberately does NOT call
# apply_default_resource_limits (lib/grading.sh) - a second, competing
# LimitRange in the same namespace would merge with this one in
# undefined/last-write-wins ways for overlapping default/defaultRequest
# values, directly invalidating what check.sh grades. Same precedent as
# q105-12-limitrange-defaults and q105-21-limitrange-min-max-bounds.
set -euo pipefail

QUESTION_ID="q111-18-limitrange-largest-allowed${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: v1
kind: LimitRange
metadata:
  name: mem-bounds
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  limits:
    - type: Container
      max:
        memory: 512Mi
      default:
        memory: 256Mi
      defaultRequest:
        memory: 128Mi
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: oven
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 3
  selector:
    matchLabels:
      app: oven
  template:
    metadata:
      labels:
        app: oven
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: oven
          image: nginx:1.27
          resources:
            requests:
              memory: 1Gi
            limits:
              memory: 1Gi
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: bread
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 1
  selector:
    matchLabels:
      app: bread
  template:
    metadata:
      labels:
        app: bread
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: bread
          image: nginx:1.27
EOF

kubectl rollout status deployment/bread -n "$QUESTION_ID" --timeout=60s || true

echo "setup.sh: $QUESTION_ID ready"
