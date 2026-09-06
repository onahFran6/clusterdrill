#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q101-40-create-configmap-from-env-file${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

WORKDIR="$(question_workdir "$QUESTION_ID")"
cat > "$WORKDIR/service.env" <<'EOF'
RETRY_COUNT=3
TIMEOUT_SECONDS=30
EOF

echo "setup.sh: $QUESTION_ID ready"
