#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q110-45-crd-ownerreference-cascade-gc${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

CRD_NAME="backupsets.ops.clusterdrill.io"

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
    plural: backupsets
    singular: backupset
    kind: BackupSet
    listKind: BackupSetList
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
                schedule:
                  type: string
EOF

kubectl wait --for=condition=Established "crd/$CRD_NAME" --timeout=60s

kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: ops.clusterdrill.io/v1
kind: BackupSet
metadata:
  name: nightly
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  schedule: "0 2 * * *"
EOF

kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: nightly-manifest
  labels:
    clusterdrill-question: $QUESTION_ID
data:
  files: "db.sql,uploads.tar"
EOF

echo "setup.sh: $QUESTION_ID ready (ConfigMap 'nightly-manifest' has no ownerReferences yet)"
