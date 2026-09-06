#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q106-08-clusterrolebinding-bind-sa${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: fleet-inspector
  labels:
    clusterdrill-question: $QUESTION_ID
EOF

kubectl apply -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: q106-08-namespace-viewer
  labels:
    clusterdrill-question: $QUESTION_ID
rules:
  - apiGroups: [""]
    resources: ["namespaces"]
    verbs: ["get", "list"]
EOF

echo "setup.sh: $QUESTION_ID ready"
