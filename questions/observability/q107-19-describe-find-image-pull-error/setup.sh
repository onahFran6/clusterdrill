#!/usr/bin/env bash
# Idempotent: creates/resets namespace q107-19-describe-find-image-pull-error
# and seeds a pod with a typo'd image tag that can never be pulled.
set -euo pipefail

QUESTION_ID="q107-19-describe-find-image-pull-error${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
kind: Pod
metadata:
  name: catalog-api
  labels:
    app: catalog-api
    clusterdrill-question: $QUESTION_ID
spec:
  containers:
    - name: catalog-api
      image: nginx:1.25-alpne
EOF

echo "setup.sh: $QUESTION_ID ready"
