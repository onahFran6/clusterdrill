#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q110-08-crd-create-instance${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

CRD_NAME="widgets.gadgets.clusterdrill.io"

kubectl apply -f - <<EOF
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: $CRD_NAME
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  group: gadgets.clusterdrill.io
  scope: Namespaced
  names:
    plural: widgets
    singular: widget
    kind: Widget
    listKind: WidgetList
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
                - color
                - weightGrams
              properties:
                color:
                  type: string
                weightGrams:
                  type: integer
EOF

# CRD registration is asynchronous - wait for it to become Established
# before anyone (candidate or this script) tries to create an instance,
# per the "CRD takes a moment" pitfall.
kubectl wait --for=condition=Established "crd/$CRD_NAME" --timeout=60s

echo "setup.sh: $QUESTION_ID ready (CRD '$CRD_NAME' established, no instances yet)"
