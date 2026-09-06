#!/usr/bin/env bash
# Idempotent: creates/resets namespace q103-42-label-selector-inequality-notequals-exclude and
# seeds five pods across four env values (two of them env=prod).

set -euo pipefail

QUESTION_ID="q103-42-label-selector-inequality-notequals-exclude${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

for pair in "svc-dev:dev" "svc-staging:staging" "svc-prod-1:prod" "svc-prod-2:prod" "svc-canary:canary"; do
  name="${pair%%:*}"
  env="${pair##*:}"
  kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: $name
  labels:
    clusterdrill-question: $QUESTION_ID
    env: $env
spec:
  containers:
    - name: $name
      image: busybox:1.36
      command: ["sleep", "3600"]
      resources:
        requests: {cpu: 25m, memory: 32Mi}
        limits: {cpu: 50m, memory: 64Mi}
EOF
done

echo "setup.sh: $QUESTION_ID ready"
