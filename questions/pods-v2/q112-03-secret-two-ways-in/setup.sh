#!/usr/bin/env bash
# Idempotent: creates/resets the namespace and seeds the Secret the
# candidate's Pod must consume. The Pod itself is NOT seeded - building it
# from scratch is the exercise.
set -euo pipefail

QUESTION_ID="q112-03-secret-two-ways-in${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: db-creds
  labels:
    clusterdrill-question: $QUESTION_ID
stringData:
  user: app
  password: "p@ss w0rd!"
EOF

echo "setup.sh: $QUESTION_ID ready"
