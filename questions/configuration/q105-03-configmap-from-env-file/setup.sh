#!/usr/bin/env bash
# Idempotent: creates/resets namespace q105-03-configmap-from-env-file and
# writes the source env file to this question's terminal working directory.
# No cluster objects besides the namespace are pre-seeded for this question.

set -euo pipefail

QUESTION_ID="q105-03-configmap-from-env-file${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

WORK_DIR="$(question_workdir "$QUESTION_ID")"
cat > "$WORK_DIR/q105-03.env" <<'EOF'
LOG_LEVEL=debug
MAX_CONNECTIONS=50
EOF

echo "setup.sh: $QUESTION_ID ready"
