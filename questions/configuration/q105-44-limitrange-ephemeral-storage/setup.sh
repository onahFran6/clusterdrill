#!/usr/bin/env bash
# Idempotent: creates/resets namespace q105-44-limitrange-ephemeral-storage.
# No LimitRange or pod is pre-seeded - the candidate authors both.
#
# NOTE: this question's own LimitRange is the graded object (its
# default/defaultRequest values must be the ones the candidate's pod picks
# up), so apply_default_resource_limits is deliberately NOT called here -
# it would stack a second, competing LimitRange whose cpu/memory
# default/defaultRequest would coexist fine, but is unnecessary noise for a
# question that is entirely about authoring this namespace's own
# ephemeral-storage LimitRange from a clean namespace. Mirrors
# q105-12-limitrange-defaults / q105-21-limitrange-min-max-bounds.

set -euo pipefail

QUESTION_ID="q105-44-limitrange-ephemeral-storage${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

echo "setup.sh: $QUESTION_ID ready"
