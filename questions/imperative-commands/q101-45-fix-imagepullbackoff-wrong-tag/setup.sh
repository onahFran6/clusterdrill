#!/usr/bin/env bash
# Idempotent: creates/resets namespace
# q101-45-fix-imagepullbackoff-wrong-tag and seeds a
# ServiceAccount plus a Pod whose image tag does not exist, so the pod sits
# in ImagePullBackOff/ErrImagePull until the candidate fixes the tag.

set -euo pipefail

QUESTION_ID="q101-45-fix-imagepullbackoff-wrong-tag${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: ci-deploy
  labels:
    clusterdrill-question: $QUESTION_ID
EOF

kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: worker-app
  labels:
    app: worker-app
    clusterdrill-question: $QUESTION_ID
spec:
  serviceAccountName: ci-deploy
  containers:
    - name: worker-app
      image: nginx:1.25-alpine-does-not-exist
      resources:
        requests:
          cpu: 25m
          memory: 32Mi
        limits:
          cpu: 50m
          memory: 64Mi
EOF

kubectl wait --for=condition=Ready pod/worker-app -n "$QUESTION_ID" --timeout=20s || true

echo "setup.sh: $QUESTION_ID ready"
