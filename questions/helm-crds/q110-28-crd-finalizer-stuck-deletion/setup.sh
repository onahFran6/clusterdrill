#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q110-28-crd-finalizer-stuck-deletion${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

CRD_NAME="archives.storage.clusterdrill.io"

kubectl apply -f - <<EOF
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: $CRD_NAME
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  group: storage.clusterdrill.io
  scope: Namespaced
  names:
    plural: archives
    singular: archive
    kind: Archive
    listKind: ArchiveList
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
                sizeGb:
                  type: integer
EOF

# CRD registration is asynchronous - wait for it to become Established
# before creating an instance against it.
kubectl wait --for=condition=Established "crd/$CRD_NAME" --timeout=60s

kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: storage.clusterdrill.io/v1
kind: Archive
metadata:
  name: cold-store-1
  finalizers:
    - storage.clusterdrill.io/cleanup
spec:
  sizeGb: 50
EOF

# Issue the delete now, in the background, without waiting - since nothing
# ever removes the finalizer, this leaves cold-store-1 with a non-null
# metadata.deletionTimestamp, stuck Terminating, by the time the candidate
# connects.
kubectl delete archive cold-store-1 -n "$QUESTION_ID" --wait=false &

# Give the delete request a moment to actually land and stamp
# deletionTimestamp before setup.sh exits, so the object is reliably
# already Terminating for the candidate (and for check.sh's unsolved-state
# run) rather than racing.
for _ in $(seq 1 20); do
  ts="$(kubectl get archive cold-store-1 -n "$QUESTION_ID" -o jsonpath='{.metadata.deletionTimestamp}' 2>/dev/null || true)"
  if [[ -n "$ts" ]]; then
    break
  fi
  sleep 0.5
done

echo "setup.sh: $QUESTION_ID ready (CRD '$CRD_NAME' established, cold-store-1 stuck Terminating)"
