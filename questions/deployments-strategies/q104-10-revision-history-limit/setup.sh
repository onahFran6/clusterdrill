#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q104-10-revision-history-limit${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: audit-log
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 2
  selector:
    matchLabels:
      app: audit-log
  template:
    metadata:
      labels:
        app: audit-log
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: audit-log
          image: nginx:1.20-alpine
EOF
kubectl rollout status deployment/audit-log -n "$QUESTION_ID" --timeout=60s || true

for tag in 1.21-alpine 1.22-alpine 1.23-alpine 1.24-alpine 1.25-alpine; do
  kubectl set image deployment/audit-log "audit-log=nginx:${tag}" -n "$QUESTION_ID"
  kubectl rollout status deployment/audit-log -n "$QUESTION_ID" --timeout=60s || true
done

echo "setup.sh: $QUESTION_ID ready (6 revisions total behind it now)"
