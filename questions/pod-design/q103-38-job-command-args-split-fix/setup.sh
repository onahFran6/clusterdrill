#!/usr/bin/env bash
# Idempotent: creates/resets namespace q103-38-job-command-args-split-fix and writes a pod
# manifest whose entire "wc -l /etc/hostname" is jammed into a single command array element (not
# valid exec argv) to this question's terminal working directory. Never applied here - the
# unsolved state has NO pod object at all (mirrors the q103-23 nodeName precedent for "unapplied
# manifest" questions).

set -euo pipefail

QUESTION_ID="q103-38-job-command-args-split-fix${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

WORK_DIR="$(question_workdir "$QUESTION_ID")"
cat > "$WORK_DIR/word-counter.yaml" <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: word-counter
  namespace: $QUESTION_ID
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  restartPolicy: Never
  containers:
    - name: word-counter
      image: busybox:1.36
      # BROKEN: this whole string is ONE argv element, not a program name
      # plus separate arguments - it will never actually run 'wc'.
      command: ["wc -l /etc/hostname"]
      resources:
        requests:
          cpu: 25m
          memory: 32Mi
        limits:
          cpu: 50m
          memory: 64Mi
EOF

echo "setup.sh: $QUESTION_ID ready (unfixed manifest at $WORK_DIR/word-counter.yaml, not yet applied)"
