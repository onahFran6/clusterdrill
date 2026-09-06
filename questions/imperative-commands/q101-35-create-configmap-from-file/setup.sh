#!/usr/bin/env bash
# Idempotent: creates/resets namespace q101-35-create-configmap-from-file and
# seeds a local file for the candidate to build a ConfigMap from with
# `kubectl create configmap --from-file`. The file lives in this question's
# terminal working directory (lib/grading.sh's question_workdir), matching
# where the candidate's terminal actually starts.

set -euo pipefail

QUESTION_ID="q101-35-create-configmap-from-file${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

WORKDIR="$(question_workdir "$QUESTION_ID")"
cat > "$WORKDIR/app.properties" <<'EOF'
log.level=warn
cache.enabled=true
EOF

echo "setup.sh: $QUESTION_ID ready"
