#!/usr/bin/env bash
# Idempotent: creates/resets the namespace and seeds shop.env into the
# candidate's own terminal cwd (not a ConfigMap - building that from the
# file is the exercise).
set -euo pipefail

QUESTION_ID="q112-02-env-file-prefixed-configmap${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

WORKDIR="$(question_workdir "$QUESTION_ID")"
printf 'THEME=dark\nCURRENCY=NGN\nMAX_CART=25\n' > "$WORKDIR/shop.env"

echo "setup.sh: $QUESTION_ID ready"
