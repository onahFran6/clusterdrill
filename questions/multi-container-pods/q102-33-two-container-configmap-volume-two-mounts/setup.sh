#!/usr/bin/env bash
# Idempotent: creates/resets namespace only, plus a ConfigMap the candidate
# must consume. The candidate builds the whole two-container Pod from
# scratch (contrast with q102-17's init-container ConfigMap *gate* - here
# two REGULAR containers both mount the same ConfigMap directly, at two
# different paths, no init container or gating logic involved).
set -euo pipefail

QUESTION_ID="q102-33-two-container-configmap-volume-two-mounts${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: shared-settings
  labels:
    clusterdrill-question: $QUESTION_ID
data:
  mode.conf: "region=eu-west-1"
EOF

echo "setup.sh: $QUESTION_ID ready"
