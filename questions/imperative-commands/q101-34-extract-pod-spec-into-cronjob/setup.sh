#!/usr/bin/env bash
# Idempotent: creates/resets namespace and seeds a running Pod
# 'legacy-report-gen' with a specific image, three env vars, and a specific
# command. The candidate must extract those exact values with
# `kubectl get pod -o jsonpath=...` (not by eyeballing the YAML) and use
# them to build a CronJob via `kubectl create cronjob --dry-run=client -o
# yaml`, then edit-and-apply. Re-running this script must always land back
# on this same known-good Pod state, not whatever the candidate left behind.

set -euo pipefail

QUESTION_ID="q101-34-extract-pod-spec-into-cronjob${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

kubectl delete pod legacy-report-gen -n "$QUESTION_ID" --ignore-not-found --wait=true >/dev/null 2>&1 || true

kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: legacy-report-gen
  labels:
    app: legacy-report-gen
    clusterdrill-question: $QUESTION_ID
spec:
  containers:
    - name: report-gen
      image: busybox:1.36
      command: ["sh", "-c", "echo Report type=\$REPORT_TYPE output=\$OUTPUT_PATH retries=\$RETRY_LIMIT && sleep 3600"]
      env:
        - name: REPORT_TYPE
          value: "weekly"
        - name: OUTPUT_PATH
          value: "/var/reports/output.txt"
        - name: RETRY_LIMIT
          value: "5"
      resources:
        requests:
          cpu: 25m
          memory: 32Mi
        limits:
          cpu: 50m
          memory: 64Mi
EOF

kubectl wait --for=condition=Ready pod/legacy-report-gen -n "$QUESTION_ID" --timeout=90s

echo "setup.sh: $QUESTION_ID ready (legacy-report-gen running, no CronJob yet)"
