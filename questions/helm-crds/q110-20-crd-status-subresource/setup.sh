#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q110-20-crd-status-subresource${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

CRD_NAME="backupjobs.ops.clusterdrill.io"

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
    plural: backupjobs
    singular: backupjob
    kind: BackupJob
    listKind: BackupJobList
  versions:
    - name: v1
      served: true
      storage: true
      subresources:
        status: {}
      schema:
        openAPIV3Schema:
          type: object
          properties:
            spec:
              type: object
              required:
                - targetPath
              properties:
                targetPath:
                  type: string
            status:
              type: object
              properties:
                phase:
                  type: string
EOF

kubectl wait --for=condition=Established "crd/$CRD_NAME" --timeout=60s

kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: ops.clusterdrill.io/v1
kind: BackupJob
metadata:
  name: nightly-backup
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  targetPath: /data/backups
EOF

echo "setup.sh: $QUESTION_ID ready (BackupJob 'nightly-backup' seeded, status.phase unset)"
