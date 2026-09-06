#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q104-23-detect-progress-deadline-exceeded${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

# Create the Deployment with a working image first and let it become ready.
kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: report-generator
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 2
  progressDeadlineSeconds: 20
  selector:
    matchLabels:
      app: report-generator
  template:
    metadata:
      labels:
        app: report-generator
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: report-generator
          image: nginx:1.25-alpine
EOF

kubectl rollout status deployment/report-generator -n "$QUESTION_ID" --timeout=60s

# Now trigger a rollout to a non-existent image tag so the new ReplicaSet's
# pods sit in ImagePullBackOff, then wait past progressDeadlineSeconds (20s)
# so the Progressing condition flips to False/ProgressDeadlineExceeded.
kubectl set image deployment/report-generator \
  report-generator=nginx:1.25-alpine-typo-xyz \
  -n "$QUESTION_ID"

sleep 35

echo "setup.sh: $QUESTION_ID ready"
