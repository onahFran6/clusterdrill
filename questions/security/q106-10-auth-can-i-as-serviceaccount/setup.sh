#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q106-10-auth-can-i-as-serviceaccount${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: ci-deployer
  labels:
    clusterdrill-question: $QUESTION_ID
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: deployment-editor
  labels:
    clusterdrill-question: $QUESTION_ID
rules:
  - apiGroups: ["apps"]
    resources: ["deployments"]
    verbs: ["create", "update"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: ci-deployer-binding
  labels:
    clusterdrill-question: $QUESTION_ID
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: deployment-editor
subjects:
  - kind: ServiceAccount
    name: ci-deployer
    namespace: $QUESTION_ID
EOF

echo "setup.sh: $QUESTION_ID ready"
