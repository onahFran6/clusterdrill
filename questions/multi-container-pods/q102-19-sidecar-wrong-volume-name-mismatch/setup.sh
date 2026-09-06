#!/usr/bin/env bash
# Idempotent: creates/resets namespace q102-19-sidecar-wrong-volume-name-mismatch
# and seeds a BROKEN pod: "sidecar"'s volumeMounts reference the typo'd (but
# schema-valid) volume name "shared-dat" instead of the shared "shared-data",
# so it silently gets its own disconnected emptyDir instead of "writer"'s
# data and crash-loops tailing a file that never appears on its own decoy
# volume. Note: the API server rejects a volumeMounts[].name that doesn't
# exist in spec.volumes at all (admission validation), so a literal "name
# not found" mismatch can't be persisted - this uses a same-shape, equally-
# common bug: mounting a DIFFERENT, also-defined volume by a near-identical
# typo'd name.
set -euo pipefail

QUESTION_ID="q102-19-sidecar-wrong-volume-name-mismatch${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: metrics-pair
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  containers:
    - name: writer
      image: busybox:1.36
      command: ["sh", "-c", "while true; do echo metric >> /var/writer/metrics.log; sleep 5; done"]
      resources:
        requests:
          cpu: 25m
          memory: 32Mi
        limits:
          cpu: 50m
          memory: 64Mi
      volumeMounts:
        - name: shared-data
          mountPath: /var/writer
    - name: sidecar
      image: busybox:1.36
      command: ["sh", "-c", "tail -f /var/sidecar/metrics.log"]
      resources:
        requests:
          cpu: 25m
          memory: 32Mi
        limits:
          cpu: 50m
          memory: 64Mi
      volumeMounts:
        - name: shared-dat
          mountPath: /var/sidecar
  volumes:
    - name: shared-data
      emptyDir: {}
    - name: shared-dat
      emptyDir: {}
EOF

echo "setup.sh: $QUESTION_ID ready"
