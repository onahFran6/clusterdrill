#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q110-09-crd-validation-required${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

CRD_NAME="ticketrequests.support.clusterdrill.io"

kubectl apply -f - <<EOF
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: $CRD_NAME
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  group: support.clusterdrill.io
  scope: Namespaced
  names:
    plural: ticketrequests
    singular: ticketrequest
    kind: TicketRequest
    listKind: TicketRequestList
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
                - priority
              properties:
                priority:
                  type: string
                  enum:
                    - low
                    - medium
                    - high
EOF

kubectl wait --for=condition=Established "crd/$CRD_NAME" --timeout=60s

echo "setup.sh: $QUESTION_ID ready (CRD '$CRD_NAME' established: spec.priority required, enum low/medium/high)"
