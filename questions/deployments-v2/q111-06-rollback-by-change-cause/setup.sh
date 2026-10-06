#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q111-06-rollback-by-change-cause${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

# Revision 1: initial release
kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: billing
  labels:
    clusterdrill-question: $QUESTION_ID
  annotations:
    kubernetes.io/change-cause: "initial 2.4.57"
spec:
  replicas: 3
  selector:
    matchLabels:
      app: billing
  template:
    metadata:
      labels:
        app: billing
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: httpd
          image: httpd:2.4.57
EOF
kubectl rollout status deployment/billing -n "$QUESTION_ID" --timeout=60s

# Revision 2: the one Finance wants back ("stable release")
kubectl set image deployment/billing httpd=httpd:2.4.58 -n "$QUESTION_ID"
kubectl annotate deployment billing -n "$QUESTION_ID" \
  kubernetes.io/change-cause="stable release" --overwrite
kubectl rollout status deployment/billing -n "$QUESTION_ID" --timeout=60s

# Revision 3: cache disabled
kubectl set env deployment/billing CACHE=off -n "$QUESTION_ID"
kubectl annotate deployment billing -n "$QUESTION_ID" \
  kubernetes.io/change-cause="disable cache" --overwrite
kubectl rollout status deployment/billing -n "$QUESTION_ID" --timeout=60s

# Revision 4: the latest, reportedly broken, release
kubectl set image deployment/billing httpd=httpd:2.4.59 -n "$QUESTION_ID"
kubectl annotate deployment billing -n "$QUESTION_ID" \
  kubernetes.io/change-cause="upgrade 2.4.59" --overwrite
kubectl rollout status deployment/billing -n "$QUESTION_ID" --timeout=60s

echo "setup.sh: $QUESTION_ID ready"
