#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q110-22-crd-additional-printer-columns${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

CRD_NAME="invoices.billing.clusterdrill.io"

kubectl apply -f - <<EOF
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: $CRD_NAME
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  group: billing.clusterdrill.io
  scope: Namespaced
  names:
    plural: invoices
    singular: invoice
    kind: Invoice
    listKind: InvoiceList
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
              required:
                - amount
                - status
              properties:
                amount:
                  type: integer
                status:
                  type: string
EOF

kubectl wait --for=condition=Established "crd/$CRD_NAME" --timeout=60s

kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: billing.clusterdrill.io/v1
kind: Invoice
metadata:
  name: inv-1001
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  amount: 250
  status: paid
---
apiVersion: billing.clusterdrill.io/v1
kind: Invoice
metadata:
  name: inv-1002
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  amount: 900
  status: pending
EOF

echo "setup.sh: $QUESTION_ID ready"
