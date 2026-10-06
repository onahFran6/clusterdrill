#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q111-16-readiness-probe-blocks-rollout${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: menu
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 3
  selector:
    matchLabels:
      app: menu
  template:
    metadata:
      labels:
        app: menu
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: nginx
          image: nginx:1.27
EOF

kubectl rollout status deployment/menu -n "$QUESTION_ID" --timeout=60s

# Adding a readiness check hitting a path that 404s - the rollout this
# starts gets stuck forever, which is the whole point of this task.
kubectl patch deployment menu -n "$QUESTION_ID" --type=json -p='[
  {"op":"add","path":"/spec/template/spec/containers/0/readinessProbe","value":{"httpGet":{"path":"/healthz","port":80},"periodSeconds":5}}
]'

echo "setup.sh: $QUESTION_ID ready"
