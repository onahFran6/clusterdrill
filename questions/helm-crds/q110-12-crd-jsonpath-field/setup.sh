#!/usr/bin/env bash
# Pre-seeds a CRD and three instances of it. The candidate's job is a
# read-only inspection task (jsonpath querying across multiple custom
# resources), so the "solution" is recorded into a ConfigMap the same way
# q110-06 records a read-only helm inspection result - check.sh can only
# ever assert live cluster state, and "the candidate looked at the right
# field" has no cluster-state footprint unless they write it somewhere.

set -euo pipefail

QUESTION_ID="q110-12-crd-jsonpath-field${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

CRD_NAME="playlists.music.clusterdrill.io"

kubectl apply -f - <<EOF
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: $CRD_NAME
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  group: music.clusterdrill.io
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
              required:
                - trackCount
              properties:
                trackCount:
                  type: integer
EOF

kubectl wait --for=condition=Established "crd/$CRD_NAME" --timeout=60s

kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: music.clusterdrill.io/v1
kind: Playlist
metadata:
  name: road-trip
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  trackCount: 12
---
apiVersion: music.clusterdrill.io/v1
kind: Playlist
metadata:
  name: focus
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  trackCount: 47
---
apiVersion: music.clusterdrill.io/v1
kind: Playlist
metadata:
  name: workout
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  trackCount: 23
EOF

echo "setup.sh: $QUESTION_ID ready (3 Playlist instances seeded)"
