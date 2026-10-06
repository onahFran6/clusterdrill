#!/usr/bin/env bash
# Idempotent: creates/resets the namespace only. Deliberately SKIPS
# apply_default_resource_limits (unlike every other question in this
# topic): this question's whole point is predicting each of 4 pods' QoS
# class from exactly what resources are and aren't declared (bronze has
# none at all, silver has only a CPU request). The repo-wide default
# ResourceQuota/LimitRange (lib/grading.sh) would silently backfill
# bronze's and silver's missing fields via its own defaultRequest/default
# values, flipping their QoS class before the candidate even starts -
# same precedent as questions/configuration/q105-12-limitrange-defaults.
set -euo pipefail

QUESTION_ID="q112-12-four-pods-four-qos-predictions${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

echo "setup.sh: $QUESTION_ID ready"
