#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q110-47-crd-switch-storage-version${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

CRD_NAME="snapshots.storagepolicy.clusterdrill.io"

kubectl apply -f - <<EOF
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: $CRD_NAME
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  group: storagepolicy.clusterdrill.io
  scope: Namespaced
  names:
    plural: snapshots
    singular: snapshot
    kind: Snapshot
    listKind: SnapshotList
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
              required: ["label"]
              properties:
                label:
                  type: string
    - name: v1
      served: true
      storage: false
      schema:
        openAPIV3Schema:
          type: object
          properties:
            spec:
              type: object
              required: ["label"]
              properties:
                label:
                  type: string
EOF

kubectl wait --for=condition=Established "crd/$CRD_NAME" --timeout=60s

kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: storagepolicy.clusterdrill.io/v1beta1
kind: Snapshot
metadata:
  name: archive-q3
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  label: "Archive Q3"
EOF

echo "setup.sh: $QUESTION_ID ready (CRD '$CRD_NAME' storage version is still v1beta1)"
