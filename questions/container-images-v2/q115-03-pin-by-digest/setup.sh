#!/usr/bin/env bash
# Idempotent: creates/resets the namespace and seeds Deployment 'web',
# already rolled out at 2 replicas on nginx:1.27. The candidate re-points
# it at a digest.
set -euo pipefail

QUESTION_ID="q115-03-pin-by-digest${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

cat <<EOF | kubectl apply -n "$QUESTION_ID" -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 2
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: nginx
          image: nginx:1.27
EOF

kubectl rollout status deployment/web -n "$QUESTION_ID" --timeout=120s

echo "setup.sh: $QUESTION_ID ready"
