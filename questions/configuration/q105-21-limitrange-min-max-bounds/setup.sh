#!/usr/bin/env bash
# Idempotent: creates/resets namespace q105-21-limitrange-min-max-bounds.
# Nothing to seed - the candidate creates everything for this question.

set -euo pipefail

QUESTION_ID="q105-21-limitrange-min-max-bounds${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

echo "setup.sh: $QUESTION_ID ready"
