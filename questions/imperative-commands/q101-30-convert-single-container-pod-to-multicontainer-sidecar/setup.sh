#!/usr/bin/env bash
# Idempotent: creates/resets namespace and seeds a running single-container
# Pod 'web-writer' (container 'main') that continuously appends timestamped
# lines to an emptyDir-backed log file. The candidate must add a second
# 'log-shipper' container to the SAME pod via generate-edit-apply, since a
# running Pod's spec.containers list cannot gain a new entry via patch.

set -euo pipefail

QUESTION_ID="q101-30-convert-single-container-pod-to-multicontainer-sidecar${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

# Re-runs of setup.sh (e.g. a candidate hitting "reset") must start from the
# same single-container state every time, not from whatever the candidate
# left behind (an already-2-container pod, a deleted pod mid-recreate,
# etc). Delete any prior web-writer first so this script is truly
# idempotent.
kubectl delete pod web-writer -n "$QUESTION_ID" --ignore-not-found --wait=true >/dev/null 2>&1 || true

kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: web-writer
  labels:
    app: web-writer
    clusterdrill-question: $QUESTION_ID
spec:
  containers:
    - name: main
      image: busybox:1.36
      command: ["sh", "-c", "mkdir -p /var/log/app; while true; do echo \"\$(date -u +%Y-%m-%dT%H:%M:%SZ) hello from main\" >> /var/log/app/output.log; sleep 2; done"]
      volumeMounts:
        - name: log-vol
          mountPath: /var/log/app
      resources:
        requests:
          cpu: 25m
          memory: 32Mi
        limits:
          cpu: 50m
          memory: 64Mi
  volumes:
    - name: log-vol
      emptyDir: {}
EOF

kubectl wait --for=condition=Ready pod/web-writer -n "$QUESTION_ID" --timeout=90s

echo "setup.sh: $QUESTION_ID ready (web-writer running with single container 'main')"
