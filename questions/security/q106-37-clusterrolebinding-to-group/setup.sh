#!/usr/bin/env bash
# Idempotent: creates/resets namespace q106-37-clusterrolebinding-to-group
# and seeds a ClusterRole to bind. The ClusterRole itself carries
# clusterdrill-question=$QUESTION_ID so cleanup can find it - a namespace
# delete alone never touches cluster-scoped objects.

set -euo pipefail

QUESTION_ID="q106-37-clusterrolebinding-to-group${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

kubectl apply -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: q106-37-namespace-viewer
  labels:
    clusterdrill-question: $QUESTION_ID
rules:
  - apiGroups: [""]
    resources: ["namespaces"]
    verbs: ["get", "list"]
EOF

echo "setup.sh: $QUESTION_ID ready (no ClusterRoleBinding exists yet - candidate creates it)"
