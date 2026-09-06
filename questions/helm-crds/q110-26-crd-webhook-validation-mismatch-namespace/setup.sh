#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q110-26-crd-webhook-validation-mismatch-namespace${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

CRD_NAME="quotas.limits.clusterdrill.io"

kubectl apply -f - <<EOF
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: $CRD_NAME
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  group: limits.clusterdrill.io
  scope: Namespaced
  names:
    plural: quotas
    singular: quota
    kind: Quota
    listKind: QuotaList
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
                - maxUsers
                - tier
              properties:
                maxUsers:
                  type: integer
                  minimum: 1
                  maximum: 100
                tier:
                  type: string
                  enum:
                    - bronze
                    - silver
                    - gold
EOF

kubectl wait --for=condition=Established "crd/$CRD_NAME" --timeout=60s

# Write the broken manifest to disk (NOT applied - candidate must fix it).
mkdir -p "$SCRIPT_DIR/manifests"
cat > "$SCRIPT_DIR/manifests/broken-quota.yaml" <<EOF
apiVersion: limits.clusterdrill.io/v1
kind: Quota
metadata:
  name: team-quota
  namespace: $QUESTION_ID
spec:
  maxUsers: 500
  tier: platinum
EOF

echo "setup.sh: $QUESTION_ID ready (CRD '$CRD_NAME' established: maxUsers 1-100, tier enum bronze/silver/gold; broken manifest written to manifests/broken-quota.yaml, not applied)"
