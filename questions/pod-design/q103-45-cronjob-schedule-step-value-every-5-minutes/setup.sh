#!/usr/bin/env bash
# Idempotent: creates/resets namespace q103-45-cronjob-schedule-step-value-every-5-minutes. No
# workload is seeded - this is an author-from-scratch question, not a fix-the-broken-thing one.

set -euo pipefail

QUESTION_ID="q103-45-cronjob-schedule-step-value-every-5-minutes${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

echo "setup.sh: $QUESTION_ID ready"
