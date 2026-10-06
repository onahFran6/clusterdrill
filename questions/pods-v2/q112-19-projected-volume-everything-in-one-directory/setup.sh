#!/usr/bin/env bash
# Idempotent: creates/resets the namespace and seeds the ConfigMap/Secret
# the candidate's projected volume must merge. The Pod itself is NOT
# seeded - building it from scratch is the exercise.
set -euo pipefail

QUESTION_ID="q112-19-projected-volume-everything-in-one-directory${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: app-cfg
  labels:
    clusterdrill-question: $QUESTION_ID
data:
  app.yaml: "replicas: 2"
---
apiVersion: v1
kind: Secret
metadata:
  name: app-sec
  labels:
    clusterdrill-question: $QUESTION_ID
stringData:
  token: s3cr3t-token
EOF

echo "setup.sh: $QUESTION_ID ready"
