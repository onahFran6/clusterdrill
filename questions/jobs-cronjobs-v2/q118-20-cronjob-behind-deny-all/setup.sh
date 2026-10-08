#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q118-20-cronjob-behind-deny-all${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
kind: Pod
metadata:
  name: report
  namespace: $NS
  labels:
    clusterdrill-question: $NS
    app: report
spec:
  restartPolicy: Always
  containers:
  - name: report
    image: busybox:1.36
    command:
    - sh
    - -c
    - mkdir -p /www && echo report ok > /www/index.html && httpd -f -p 8080 -h /www
---
apiVersion: v1
kind: Pod
metadata:
  name: other
  namespace: $NS
  labels:
    clusterdrill-question: $NS
spec:
  containers:
  - name: other
    image: busybox:1.36
    command:
    - sleep
    - '3600'
---
apiVersion: v1
kind: Service
metadata:
  name: report-svc
  namespace: $NS
  labels:
    clusterdrill-question: $NS
spec:
  selector:
    app: report
  ports:
  - port: 8080
    targetPort: 8080
    protocol: TCP
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all
  namespace: $NS
  labels:
    clusterdrill-question: $NS
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
---
apiVersion: batch/v1
kind: CronJob
metadata:
  name: reporter
  namespace: $NS
  labels:
    clusterdrill-question: $NS
spec:
  schedule: '*/15 * * * *'
  jobTemplate:
    spec:
      template:
        spec:
          restartPolicy: Never
          containers:
          - name: reporter
            image: busybox:1.36
            command:
            - wget
            - -qO-
            - -T
            - '5'
            - report-svc:8080
YAML
kubectl wait -n "$NS" --for=condition=Ready pod/report pod/other --timeout=90s

echo "setup.sh: $QUESTION_ID ready"
