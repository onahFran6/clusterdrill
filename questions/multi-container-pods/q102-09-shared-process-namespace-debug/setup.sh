#!/usr/bin/env bash
# Idempotent: creates/resets namespace q102-09-shared-process-namespace-debug and seeds broken/partial resources.
# Every object created here - namespaced or cluster-scoped - MUST carry the
# label clusterdrill-question=q102-09-shared-process-namespace-debug. Never assume
# this is the first run: full_reset (lib/grading.sh) already ran before this
# script whenever it matters, but setup.sh itself
# must still be safe to re-run standalone without erroring or duplicating.

set -euo pipefail

QUESTION_ID="q102-09-shared-process-namespace-debug${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

echo "setup.sh: $QUESTION_ID ready"
