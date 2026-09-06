#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q107-17-logs-since-time-window${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: ticker
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  containers:
    - name: ticker
      image: busybox:1.36
      command: ["sh", "-c", "i=0; while true; do i=\$((i+1)); echo \"tick \$i\"; sleep 1; done"]
      resources:
        requests:
          cpu: "50m"
          memory: "32Mi"
        limits:
          cpu: "100m"
          memory: "64Mi"
EOF

kubectl wait --for=condition=Ready pod/ticker -n "$QUESTION_ID" --timeout=60s

# Make sure there is a long scrollback (at least 30 lines) before the
# candidate ever looks at the logs, so a plain `kubectl logs` without
# --tail would show far more than the last 5 lines.
for _ in $(seq 1 30); do
  line_count="$(kubectl logs ticker -n "$QUESTION_ID" 2>/dev/null | wc -l | tr -d ' ')"
  if [[ "$line_count" -ge 30 ]]; then
    break
  fi
  sleep 1
done

# Clean up any pre-existing tail file from a previous run of this question.
WORK_DIR="$(question_workdir "$QUESTION_ID")"
rm -f "$WORK_DIR/ticker-tail.txt"

echo "setup.sh: $QUESTION_ID ready"
