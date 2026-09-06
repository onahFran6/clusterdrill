#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q110-30-crd-crossnamespace-count-and-cleanup${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SECOND_NS="${QUESTION_ID}-b"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

# The second namespace has no framework-level cleanup path (full_reset only
# knows the primary $QUESTION_ID namespace by exact name), so setup.sh is
# responsible for its own idempotency: always start by removing any
# leftover copy from a previous run of this question before recreating it.
kubectl delete namespace "$SECOND_NS" --ignore-not-found --wait=true >/dev/null 2>&1

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

kubectl create namespace "$SECOND_NS" \
  --dry-run=client -o yaml | kubectl apply -f -
apply_default_resource_limits "$SECOND_NS"
grant_user_namespace_access "$SECOND_NS" "${CLUSTERDRILL_USER_ID:-}"

CRD_NAME="endpointprobes.monitoring.clusterdrill.io"

# --- Step 1: install the CRD with a temporarily relaxed schema (no
# minimum on intervalSeconds) so we can force-create two pre-existing
# "bad data" instances that predate the constraint. ---
kubectl apply -f - <<EOF
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: $CRD_NAME
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  group: monitoring.clusterdrill.io
  scope: Namespaced
  names:
    plural: endpointprobes
    singular: endpointprobe
    kind: EndpointProbe
    listKind: EndpointProbeList
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
                - url
                - intervalSeconds
              properties:
                url:
                  type: string
                intervalSeconds:
                  type: integer
EOF

kubectl wait --for=condition=Established "crd/$CRD_NAME" --timeout=60s

# --- Step 2: while the schema is relaxed, force-create the two
# constraint-violating instances in the second namespace. ---
kubectl apply -f - <<EOF
apiVersion: monitoring.clusterdrill.io/v1
kind: EndpointProbe
metadata:
  name: probe-cache
  namespace: $SECOND_NS
spec:
  url: "https://cache.internal.example.com/health"
  intervalSeconds: 3
---
apiVersion: monitoring.clusterdrill.io/v1
kind: EndpointProbe
metadata:
  name: probe-legacy
  namespace: $SECOND_NS
spec:
  url: "https://legacy.internal.example.com/health"
  intervalSeconds: 1
EOF

# --- Step 3: restore the CRD to its strict, now-enforced schema
# (minimum: 5 on intervalSeconds). The two instances created above are
# NOT re-validated by this update - they remain on the cluster as
# already-stored pre-existing bad data, simulating drift that predates
# the constraint. ---
kubectl apply -f - <<EOF
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: $CRD_NAME
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  group: monitoring.clusterdrill.io
  scope: Namespaced
  names:
    plural: endpointprobes
    singular: endpointprobe
    kind: EndpointProbe
    listKind: EndpointProbeList
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
                - url
                - intervalSeconds
              properties:
                url:
                  type: string
                intervalSeconds:
                  type: integer
                  minimum: 5
EOF

kubectl wait --for=condition=Established "crd/$CRD_NAME" --timeout=60s

# --- Step 4: create the three valid instances normally, now that the
# strict schema is back in force. ---
kubectl apply -f - <<EOF
apiVersion: monitoring.clusterdrill.io/v1
kind: EndpointProbe
metadata:
  name: probe-api
  namespace: $QUESTION_ID
spec:
  url: "https://api.internal.example.com/health"
  intervalSeconds: 30
---
apiVersion: monitoring.clusterdrill.io/v1
kind: EndpointProbe
metadata:
  name: probe-web
  namespace: $QUESTION_ID
spec:
  url: "https://web.internal.example.com/health"
  intervalSeconds: 10
---
apiVersion: monitoring.clusterdrill.io/v1
kind: EndpointProbe
metadata:
  name: probe-db
  namespace: $SECOND_NS
spec:
  url: "https://db.internal.example.com/health"
  intervalSeconds: 60
EOF

echo "setup.sh: $QUESTION_ID ready (CRD '$CRD_NAME' strict, minimum intervalSeconds 5; valid probes probe-api/probe-web in $QUESTION_ID, probe-db in $SECOND_NS; invalid pre-existing probe-cache/probe-legacy in $SECOND_NS)"
