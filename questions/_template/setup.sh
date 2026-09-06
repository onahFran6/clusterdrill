#!/usr/bin/env bash
# Idempotent: creates/resets namespace qNNN and seeds broken/partial resources.
# Every object created here - namespaced or cluster-scoped - MUST carry the
# label clusterdrill-question=qNNN. Never assume
# this is the first run: full_reset (lib/grading.sh) already ran before this
# script whenever it matters, but setup.sh itself
# must still be safe to re-run standalone without erroring or duplicating.

set -euo pipefail

QUESTION_ID="qNNN${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

# --- Seed resources below. Every manifest must include:
#   metadata:
#     labels:
#       clusterdrill-question: qNNN
#
# Example:
# kubectl apply -n "$QUESTION_ID" -f - <<EOF
# apiVersion: v1
# kind: ConfigMap
# metadata:
#   name: example
#   labels:
#     clusterdrill-question: $QUESTION_ID
# data:
#   key: value
# EOF

echo "setup.sh: $QUESTION_ID ready"
