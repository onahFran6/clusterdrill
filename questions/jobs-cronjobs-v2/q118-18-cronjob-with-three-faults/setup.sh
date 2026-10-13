#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q118-18-cronjob-with-three-faults${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

NS="$QUESTION_ID"
kubectl create namespace "$NS" --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$NS" "clusterdrill-question=$NS" --overwrite
apply_default_resource_limits "$NS"
grant_user_namespace_access "$NS" "${CLUSTERDRILL_USER_ID:-}"
kubectl apply -n "$NS" -f - <<YAML
apiVersion: v1
kind: Secret
metadata:
  name: report-secret
  namespace: $NS
  labels:
    clusterdrill-question: $NS
type: Opaque
stringData:
  token: abc123
YAML
WORK_DIR="$(question_workdir "$QUESTION_ID")"
cat > "$WORK_DIR/report-cj.yaml" <<YAML
apiVersion: batch/v1
kind: CronJob
metadata:
  name: report
  namespace: $NS
  labels:
    clusterdrill-question: $NS
spec:
  schedule: '*/5 * * *'
  jobTemplate:
    spec:
      template:
        spec:
          restartPolicy: Always
          containers:
          - name: report
            image: busybox:1.36
            command:
            - sh
            - -c
            - '[ -n "\$TOKEN" ] && echo report sent'
            env:
            - name: TOKEN
              valueFrom:
                secretKeyRef:
                  name: report-secret
                  key: TOKEN
YAML

echo "setup.sh: $QUESTION_ID ready"
