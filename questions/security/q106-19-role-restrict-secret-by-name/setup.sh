#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q106-19-role-restrict-secret-by-name${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
kind: Secret
metadata:
  name: db-credentials
  labels:
    clusterdrill-question: $QUESTION_ID
stringData:
  username: report_ro
  password: change-me
---
apiVersion: v1
kind: Secret
metadata:
  name: payment-api-key
  labels:
    clusterdrill-question: $QUESTION_ID
stringData:
  api-key: not-for-reports
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: report-service
  labels:
    clusterdrill-question: $QUESTION_ID
EOF

echo "setup.sh: $QUESTION_ID ready"
