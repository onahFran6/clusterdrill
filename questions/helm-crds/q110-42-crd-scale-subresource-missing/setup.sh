#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q110-42-crd-scale-subresource-missing${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

CRD_NAME="workerpools.ops.clusterdrill.io"

kubectl apply -f - <<EOF
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: $CRD_NAME
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  group: ops.clusterdrill.io
  scope: Namespaced
  names:
    plural: workerpools
    singular: workerpool
    kind: WorkerPool
    listKind: WorkerPoolList
  versions:
    - name: v1
      served: true
      storage: true
      schema:
        openAPIV3Schema:
          type: object
          properties:
            spec:
              type: object
              properties:
                replicas:
                  type: integer
            status:
              type: object
              properties:
                replicas:
                  type: integer
                selector:
                  type: string
EOF

kubectl wait --for=condition=Established "crd/$CRD_NAME" --timeout=60s

kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: ops.clusterdrill.io/v1
kind: WorkerPool
metadata:
  name: pool-a
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 2
status:
  replicas: 2
  selector: "app=pool-a"
EOF

echo "setup.sh: $QUESTION_ID ready (CRD '$CRD_NAME' has no scale subresource yet; instance 'pool-a' has spec.replicas=2)"
