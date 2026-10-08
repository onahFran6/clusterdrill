#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q118-10-a-job-you-cant-edit${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

NS="$QUESTION_ID"
kubectl create namespace "$NS" --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$NS" "clusterdrill-question=$NS" --overwrite
apply_default_resource_limits "$NS"
grant_user_namespace_access "$NS" "${CLUSTERDRILL_USER_ID:-}"
kubectl delete job export -n "$NS" --ignore-not-found --wait=true >/dev/null
kubectl apply -n "$NS" -f - <<YAML
apiVersion: batch/v1
kind: Job
metadata:
  name: export
  namespace: $NS
  labels:
    clusterdrill-question: $NS
spec:
  suspend: true
  template:
    spec:
      restartPolicy: Never
      containers:
      - name: export
        image: busybox:1.366
        command:
        - echo
        - exporting
YAML

echo "setup.sh: $QUESTION_ID ready"
