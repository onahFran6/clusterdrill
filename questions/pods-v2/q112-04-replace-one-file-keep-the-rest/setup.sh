#!/usr/bin/env bash
# Idempotent: creates/resets the namespace and seeds the ConfigMap the
# candidate's Pod must consume. The Pod itself is NOT seeded.
set -euo pipefail

QUESTION_ID="q112-04-replace-one-file-keep-the-rest${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: site
  labels:
    clusterdrill-question: $QUESTION_ID
data:
  index.html: |
    <h1>Ganymede</h1>
  health.html: |
    ok
EOF

echo "setup.sh: $QUESTION_ID ready"
