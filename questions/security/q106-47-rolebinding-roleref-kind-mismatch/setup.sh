#!/usr/bin/env bash
# Idempotent: creates/resets namespace q106-47-rolebinding-roleref-kind-mismatch
# and seeds a Role and a ClusterRole that deliberately share the exact same
# name ('q106-47-secret-reader') but grant different things, plus a
# RoleBinding whose roleRef.kind points at the wrong one of the two. The
# ClusterRole carries clusterdrill-question=$QUESTION_ID so cleanup can
# find it - a namespace delete alone never touches cluster-scoped objects.

set -euo pipefail

QUESTION_ID="q106-47-rolebinding-roleref-kind-mismatch${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: auditor
  labels:
    clusterdrill-question: $QUESTION_ID
EOF

# The Role the candidate actually needs bound: grants get/list on secrets.
kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: q106-47-secret-reader
  labels:
    clusterdrill-question: $QUESTION_ID
rules:
  - apiGroups: [""]
    resources: ["secrets"]
    verbs: ["get", "list"]
EOF

# A decoy ClusterRole with the EXACT SAME NAME as the Role above, but
# granting something unrelated (get on configmaps, cluster-wide). Nothing
# stops a Role and a ClusterRole from sharing a name - roleRef.kind is what
# disambiguates which one a RoleBinding actually resolves to.
kubectl apply -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: q106-47-secret-reader
  labels:
    clusterdrill-question: $QUESTION_ID
rules:
  - apiGroups: [""]
    resources: ["configmaps"]
    verbs: ["get"]
EOF

# The bug: roleRef.kind is ClusterRole, so this binding resolves to the
# decoy (configmaps get) instead of the Role (secrets get/list) despite
# both being named identically.
kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: auditor-binding
  labels:
    clusterdrill-question: $QUESTION_ID
subjects:
  - kind: ServiceAccount
    name: auditor
    namespace: $QUESTION_ID
roleRef:
  kind: ClusterRole
  name: q106-47-secret-reader
  apiGroup: rbac.authorization.k8s.io
EOF

echo "setup.sh: $QUESTION_ID ready"
