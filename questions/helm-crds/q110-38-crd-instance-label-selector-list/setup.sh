#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q110-38-crd-instance-label-selector-list${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

# question_workdir persists across runs (full_reset only tears down cluster
# state) - clear any stale output file from a previous attempt so the
# unsolved state can't accidentally pass on leftover data.
rm -f "$(question_workdir "$QUESTION_ID")/edge-nodes.txt"

CRD_NAME="fleetnodes.fleet.clusterdrill.io"

kubectl apply -f - <<EOF
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: $CRD_NAME
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  group: fleet.clusterdrill.io
  scope: Namespaced
  names:
    plural: fleetnodes
    singular: fleetnode
    kind: FleetNode
    listKind: FleetNodeList
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
                region:
                  type: string
EOF

kubectl wait --for=condition=Established "crd/$CRD_NAME" --timeout=60s

for entry in "node-a:edge" "node-b:core" "node-c:edge"; do
  name="${entry%%:*}"
  tier="${entry##*:}"
  kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: fleet.clusterdrill.io/v1
kind: FleetNode
metadata:
  name: $name
  labels:
    tier: $tier
    clusterdrill-question: $QUESTION_ID
spec:
  region: us-west
EOF
done

echo "setup.sh: $QUESTION_ID ready (CRD '$CRD_NAME' established; 3 FleetNode instances created)"
