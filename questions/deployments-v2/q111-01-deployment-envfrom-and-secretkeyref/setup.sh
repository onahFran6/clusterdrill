#!/usr/bin/env bash
# Idempotent: creates/resets namespace and seeds the ConfigMap/Secret the
# candidate's Deployment must consume. The Deployment itself is NOT seeded -
# building it from scratch is the exercise.
set -euo pipefail

QUESTION_ID="q111-01-deployment-envfrom-and-secretkeyref${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
kind: ConfigMap
metadata:
  name: api-config
  labels:
    clusterdrill-question: $QUESTION_ID
data:
  LOG_LEVEL: info
  REGION: eu-west
---
apiVersion: v1
kind: Secret
metadata:
  name: api-creds
  labels:
    clusterdrill-question: $QUESTION_ID
stringData:
  DB_USER: admin
  DB_PASSWORD: s3cr3t
EOF

echo "setup.sh: $QUESTION_ID ready"
