#!/usr/bin/env bash
# Idempotent: creates/resets namespace q106-49-clusterrole-nonresourceurl-healthz
# and seeds a ServiceAccount. The ClusterRole/ClusterRoleBinding the
# candidate creates are cluster-scoped and must carry
# clusterdrill-question=$QUESTION_ID so cleanup can find them.

set -euo pipefail

QUESTION_ID="q106-49-clusterrole-nonresourceurl-healthz${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
kind: ServiceAccount
metadata:
  name: health-prober
  labels:
    clusterdrill-question: $QUESTION_ID
EOF

echo "setup.sh: $QUESTION_ID ready (no ClusterRole/ClusterRoleBinding exists yet - candidate creates them)"
