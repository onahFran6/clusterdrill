#!/usr/bin/env bash
# Idempotent: creates/resets namespace q102-37-sidecar-downward-api-podname-missing
# and seeds a BROKEN Pod. "app" writes heartbeat lines to a shared emptyDir,
# tagging each with its own POD_NAME (populated correctly via the Downward
# API, fieldRef: metadata.name). "shipper" (log-shipping sidecar) is
# supposed to prefix every shipped line with the SAME POD_NAME so a
# downstream log aggregator can tell which Pod a line came from, but
# "shipper"'s own container spec never defines POD_NAME via the Downward
# API at all - it's simply missing - so shipper always prefixes lines with
# the literal string "unknown-pod" instead of the real Pod name. Nothing
# crashes; both containers report Running the whole time.
set -euo pipefail

QUESTION_ID="q102-37-sidecar-downward-api-podname-missing${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: tagged-shipper
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  containers:
    - name: app
      image: busybox:1.36
      env:
        - name: POD_NAME
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
      command: ["sh", "-c", "mkdir -p /logs; echo \"\$POD_NAME: request handled\" >> /logs/app.log; while true; do sleep 3600; done"]
      volumeMounts:
        - name: logs
          mountPath: /logs
      resources:
        requests:
          cpu: 25m
          memory: 32Mi
        limits:
          cpu: 50m
          memory: 64Mi
    - name: shipper
      image: busybox:1.36
      command: ["sh", "-c", "i=0; while [ \$i -lt 60 ]; do if [ -f /logs/app.log ]; then echo \"[\${POD_NAME:-unknown-pod}] \$(cat /logs/app.log)\" > /logs/shipped.log; fi; i=\$((i+1)); sleep 3; done; while true; do sleep 3600; done"]
      volumeMounts:
        - name: logs
          mountPath: /logs
      resources:
        requests:
          cpu: 25m
          memory: 32Mi
        limits:
          cpu: 50m
          memory: 64Mi
  volumes:
    - name: logs
      emptyDir: {}
EOF

echo "setup.sh: $QUESTION_ID ready"
