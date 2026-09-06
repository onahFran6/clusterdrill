#!/usr/bin/env bash
# Idempotent: creates/resets namespace q106-44-clusterrolebinding-...-mismatch
# and seeds a ServiceAccount, a ClusterRole, and a ClusterRoleBinding whose
# subject namespace is deliberately wrong (copy-pasted from a different
# namespace) - the binding technically exists and is bound to the right
# ClusterRole, but its subject points at a ServiceAccount named 'deployer'
# in namespace 'default', not the one actually running here. Every
# cluster-scoped object carries clusterdrill-question=$QUESTION_ID so
# cleanup can find it.

set -euo pipefail

QUESTION_ID="q106-44-clusterrolebinding-serviceaccount-namespace-mismatch${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: deployer
  labels:
    clusterdrill-question: $QUESTION_ID
EOF

kubectl apply -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: q106-44-deployment-manager
  labels:
    clusterdrill-question: $QUESTION_ID
rules:
  - apiGroups: ["apps"]
    resources: ["deployments"]
    verbs: ["get", "list", "create", "update"]
EOF

# The bug: subjects[0].namespace is "default", not "$QUESTION_ID" - the
# ServiceAccount that actually needs this grant lives in this question's
# own namespace, so this binding never applies to it.
kubectl apply -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: q106-44-deployer-binding
  labels:
    clusterdrill-question: $QUESTION_ID
subjects:
  - kind: ServiceAccount
    name: deployer
    namespace: default
roleRef:
  kind: ClusterRole
  name: q106-44-deployment-manager
  apiGroup: rbac.authorization.k8s.io
EOF

echo "setup.sh: $QUESTION_ID ready"
