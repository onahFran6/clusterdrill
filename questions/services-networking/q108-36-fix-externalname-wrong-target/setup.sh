#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q108-36-fix-externalname-wrong-target${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
kind: Service
metadata:
  name: legacy-api-svc
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  type: ExternalName
  externalName: old-legacy-host.example.internal
EOF

echo "setup.sh: $QUESTION_ID ready"
