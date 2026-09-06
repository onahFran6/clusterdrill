#!/usr/bin/env bash
# Idempotent: creates/resets namespace q106-28-chained-rbac-role-wrong-apigroup
# and seeds a ServiceAccount + a Role whose rule for 'deployments' is
# deliberately broken (apiGroups: [""] instead of ["apps"]), already bound
# to that ServiceAccount via a correctly-named RoleBinding, plus a real
# Deployment for the candidate to prove read access against once fixed.
set -euo pipefail

QUESTION_ID="q106-28-chained-rbac-role-wrong-apigroup${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: ci-bot
  labels:
    clusterdrill-question: $QUESTION_ID
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: deploy-reader
  labels:
    clusterdrill-question: $QUESTION_ID
rules:
  - apiGroups: [""]
    resources: ["deployments"]
    verbs: ["get", "list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: ci-bot-binding
  labels:
    clusterdrill-question: $QUESTION_ID
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: deploy-reader
subjects:
  - kind: ServiceAccount
    name: ci-bot
    namespace: $QUESTION_ID
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: payments-api
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 2
  selector:
    matchLabels:
      app: payments-api
  template:
    metadata:
      labels:
        app: payments-api
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: nginx
          image: nginx
          resources:
            requests:
              cpu: 25m
              memory: 32Mi
            limits:
              cpu: 50m
              memory: 64Mi
EOF

echo "setup.sh: $QUESTION_ID ready"
