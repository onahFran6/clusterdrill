#!/usr/bin/env bash
# Idempotent: creates/resets namespace and applies a Pod with 3 sequential
# init containers where the SECOND one deliberately fails (exits 1). Init
# containers run one at a time in order, so 'fetch-config' never runs and
# the main container never starts - the candidate must find which of the
# three is actually broken, not assume it's the first.

set -euo pipefail

QUESTION_ID="q107-39-multiple-init-containers-sequential-failure${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: report-builder
  labels:
    app: report-builder
    clusterdrill-question: $QUESTION_ID
spec:
  initContainers:
    - name: create-workdir
      image: busybox:1.36
      command: ["sh", "-c", "mkdir -p /work/data && echo workdir-ready"]
    - name: fetch-config
      image: busybox:1.36
      command: ["sh", "-c", "echo 'fetch-config: required CONFIG_URL not set' >&2; exit 1"]
    - name: validate-config
      image: busybox:1.36
      command: ["sh", "-c", "echo config-valid"]
  containers:
    - name: report-builder
      image: nginx:1.25-alpine
EOF

sleep 10

echo "setup.sh: $QUESTION_ID ready (report-builder stuck at Init - the 2nd init container, fetch-config, is the one failing)"
