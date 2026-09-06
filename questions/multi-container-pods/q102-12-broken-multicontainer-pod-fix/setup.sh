#!/usr/bin/env bash
# Idempotent: creates/resets namespace q102-12-broken-multicontainer-pod-fix
# and seeds a BROKEN pod: "reader"'s volumeMounts reference the wrong (but
# schema-valid) volume name "empty-vol" instead of the shared "cache-vol",
# so it never sees writer's data and crash-loops tailing a file that never
# appears on its own decoy volume. Note: the API server rejects a
# volumeMounts[].name that doesn't exist in spec.volumes at all (admission
# validation), so a literal "name not found" mismatch can't be persisted -
# this uses a same-shape, equally-common bug: mounting the WRONG valid
# volume name.
set -euo pipefail

QUESTION_ID="q102-12-broken-multicontainer-pod-fix${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: broken-app
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  containers:
    - name: writer
      image: busybox:1.36
      command: ["sh", "-c", "while true; do echo hello >> /cache/data.txt; sleep 5; done"]
      volumeMounts:
        - name: cache-vol
          mountPath: /cache
    - name: reader
      image: busybox:1.36
      command: ["sh", "-c", "tail -f /cache/data.txt"]
      volumeMounts:
        - name: empty-vol
          mountPath: /cache
  volumes:
    - name: cache-vol
      emptyDir: {}
    - name: empty-vol
      emptyDir: {}
EOF

echo "setup.sh: $QUESTION_ID ready"
