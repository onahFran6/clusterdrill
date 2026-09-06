#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q110-24-crd-conversion-webhook-none-multi-version${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

CRD_NAME="reports.analytics.clusterdrill.io"

kubectl apply -f - <<EOF
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: $CRD_NAME
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  group: analytics.clusterdrill.io
  scope: Namespaced
  names:
    plural: reports
    singular: report
    kind: Report
    listKind: ReportList
  versions:
    - name: v1beta1
      served: true
      storage: true
      schema:
        openAPIV3Schema:
          type: object
          properties:
            spec:
              type: object
              required:
                - title
              properties:
                title:
                  type: string
EOF

kubectl wait --for=condition=Established "crd/$CRD_NAME" --timeout=60s

kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: analytics.clusterdrill.io/v1beta1
kind: Report
metadata:
  name: q3-summary
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  title: "Q3 Summary"
EOF

echo "setup.sh: $QUESTION_ID ready (CRD '$CRD_NAME' has only v1beta1; instance q3-summary exists)"
