#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q118-19-quota-blocks-pods-with-no-resources${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

NS="$QUESTION_ID"
kubectl create namespace "$NS" --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$NS" "clusterdrill-question=$NS" --overwrite
# No LimitRange: missing resources must reproduce quota admission failure.
grant_user_namespace_access "$NS" "${CLUSTERDRILL_USER_ID:-}"
kubectl apply -n "$NS" -f - <<YAML
apiVersion: v1
kind: ResourceQuota
metadata:
  name: compute
  namespace: $NS
  labels:
    clusterdrill-question: $NS
spec:
  hard:
    pods: '12'
    requests.cpu: '1'
    requests.memory: 1Gi
    limits.cpu: '2'
    limits.memory: 2Gi
---
apiVersion: batch/v1
kind: CronJob
metadata:
  name: digest
  namespace: $NS
  labels:
    clusterdrill-question: $NS
spec:
  schedule: '*/1 * * * *'
  jobTemplate:
    spec:
      template:
        spec:
          restartPolicy: Never
          containers:
          - name: digest
            image: busybox:1.36
            command:
            - echo
            - digest done
YAML
kubectl create job digest-blocked -n "$NS" --from=cronjob/digest --dry-run=client -o yaml | kubectl apply -f -

echo "setup.sh: $QUESTION_ID ready"
