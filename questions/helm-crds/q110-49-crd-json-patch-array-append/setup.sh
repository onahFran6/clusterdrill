#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q110-49-crd-json-patch-array-append${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

CRD_NAME="playlists.media.clusterdrill.io"

kubectl apply -f - <<EOF
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: $CRD_NAME
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  group: media.clusterdrill.io
  scope: Namespaced
  names:
    plural: playlists
    singular: playlist
    kind: Playlist
    listKind: PlaylistList
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
                tracks:
                  type: array
                  items:
                    type: string
EOF

kubectl wait --for=condition=Established "crd/$CRD_NAME" --timeout=60s

kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: media.clusterdrill.io/v1
kind: Playlist
metadata:
  name: mix1
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  tracks:
    - "song-a"
    - "song-b"
EOF

echo "setup.sh: $QUESTION_ID ready"
