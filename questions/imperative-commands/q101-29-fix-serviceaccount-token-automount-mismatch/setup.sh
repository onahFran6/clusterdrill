#!/usr/bin/env bash
# Idempotent: creates/resets namespace and seeds a correctly-wired
# ServiceAccount/Role/RoleBinding trio, but the pod meant to use that
# identity ('introspector') is broken two ways at once - it runs as the
# 'default' ServiceAccount instead of 'reader-sa', AND it explicitly sets
# automountServiceAccountToken=false, so it has no token mounted at all.
set -euo pipefail

QUESTION_ID="q101-29-fix-serviceaccount-token-automount-mismatch${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: reader-sa
  labels:
    clusterdrill-question: $QUESTION_ID
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-reader
  labels:
    clusterdrill-question: $QUESTION_ID
rules:
  - apiGroups: [""]
    resources: ["pods"]
    verbs: ["get", "list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: reader-sa-pod-reader-binding
  labels:
    clusterdrill-question: $QUESTION_ID
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: pod-reader
subjects:
  - kind: ServiceAccount
    name: reader-sa
    namespace: $QUESTION_ID
EOF

# Broken pod: wrong (default) ServiceAccount AND automount explicitly
# disabled, so it has neither the right identity nor any token at all.
kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: introspector
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  serviceAccountName: default
  automountServiceAccountToken: false
  containers:
    - name: introspector
      image: bitnami/kubectl:latest
      command: ["sleep", "3600"]
      resources:
        requests:
          cpu: "25m"
          memory: "32Mi"
        limits:
          cpu: "50m"
          memory: "64Mi"
EOF

echo "setup.sh: $QUESTION_ID ready"
