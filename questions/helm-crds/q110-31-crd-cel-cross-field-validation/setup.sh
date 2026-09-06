#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q110-31-crd-cel-cross-field-validation${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

CRD_NAME="budgets.finance.clusterdrill.io"

kubectl apply -f - <<EOF
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: $CRD_NAME
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  group: finance.clusterdrill.io
  scope: Namespaced
  names:
    plural: budgets
    singular: budget
    kind: Budget
    listKind: BudgetList
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
              required: ["limit", "reserved"]
              properties:
                limit:
                  type: integer
                  minimum: 1
                reserved:
                  type: integer
                  minimum: 0
              x-kubernetes-validations:
                - rule: "self.reserved <= self.limit"
                  message: "reserved must not exceed limit"
EOF

# CRD registration (and CEL rule compilation) is asynchronous - wait for it
# to become Established before the candidate can create an instance
# against it.
kubectl wait --for=condition=Established "crd/$CRD_NAME" --timeout=60s

echo "setup.sh: $QUESTION_ID ready (CRD '$CRD_NAME' established with an undocumented CEL cross-field rule; candidate creates the instance)"
