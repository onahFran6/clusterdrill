#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q111-15-progress-deadline-then-rollback${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: ring
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 4
  selector:
    matchLabels:
      app: ring
  template:
    metadata:
      labels:
        app: ring
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: nginx
          image: nginx:1.25
EOF

kubectl rollout status deployment/ring -n "$QUESTION_ID" --timeout=60s

# Break it with a nonexistent tag - the rollout this starts never finishes
# on its own, which is the whole point of this task.
kubectl set image deployment/ring nginx=nginx:1.277 -n "$QUESTION_ID"

echo "setup.sh: $QUESTION_ID ready"
