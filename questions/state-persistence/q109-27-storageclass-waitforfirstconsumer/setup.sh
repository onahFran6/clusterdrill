#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q109-27-storageclass-waitforfirstconsumer${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

# This cluster's minikube storage-provisioner service account is only
# granted the bootstrapping "system:persistent-volume-provisioner"
# ClusterRole, which does not include "get" on nodes. That is enough for
# Immediate-binding StorageClasses (the "standard" default), but
# WaitForFirstConsumer provisioning reads the PVC's
# "volume.kubernetes.io/selected-node" annotation and then calls the API
# server to fetch that Node object - without "get" on nodes this fails
# with "cannot get resource nodes ... forbidden" and the PVC never leaves
# Pending, even after a consumer Pod exists. Grant that single missing
# permission narrowly (separate ClusterRole/ClusterRoleBinding, not an
# edit to minikube's own addon-managed objects) so dynamic provisioning
# with WaitForFirstConsumer actually works for this question.
kubectl apply -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: $QUESTION_ID-node-reader
  labels:
    clusterdrill-question: $QUESTION_ID
rules:
  - apiGroups: [""]
    resources: ["nodes"]
    verbs: ["get"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: $QUESTION_ID-node-reader
  labels:
    clusterdrill-question: $QUESTION_ID
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: $QUESTION_ID-node-reader
subjects:
  - kind: ServiceAccount
    name: storage-provisioner
    namespace: kube-system
EOF

echo "setup.sh: $QUESTION_ID ready"
