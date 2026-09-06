#!/usr/bin/env bash
# Idempotent: creates/resets namespace and applies a Pod whose livenessProbe
# tries to use a shell pipe inside a bare exec command array. exec probes
# run the command directly with no shell involved, so "|" is passed to
# `cat` as a literal filename argument rather than being interpreted as a
# pipe - `cat` then fails trying to open nonexistent files named "|",
# "grep", and "ok", so the probe fails and kills the container in a loop
# even though the app itself is healthy and really is writing "ok".

set -euo pipefail

QUESTION_ID="q107-46-livenessprobe-exec-array-vs-shell-pipeline${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: status-writer
  labels:
    app: status-writer
    clusterdrill-question: $QUESTION_ID
spec:
  containers:
    - name: status-writer
      image: busybox:1.36
      command: ["sh", "-c", "while true; do echo ok > /tmp/status; sleep 1; done"]
      livenessProbe:
        exec:
          command: ["cat", "/tmp/status", "|", "grep", "ok"]
        initialDelaySeconds: 3
        periodSeconds: 2
        failureThreshold: 1
EOF

sleep 15

echo "setup.sh: $QUESTION_ID ready (status-writer is genuinely healthy but crash-looping - the livenessProbe's bare exec array can't use a shell pipe)"
