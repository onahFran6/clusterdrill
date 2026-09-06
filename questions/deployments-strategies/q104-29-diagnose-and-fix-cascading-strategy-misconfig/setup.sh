#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q104-29-diagnose-and-fix-cascading-strategy-misconfig${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

# Step 1: create a healthy Deployment with a correct readinessProbe and the
# default (safe) strategy, and wait for it to actually become ready first -
# so the subsequent broken rollout is a real regression, not a first-ever
# rollout that just never worked.
kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: payments-web
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 2
  selector:
    matchLabels:
      app: payments-web
  template:
    metadata:
      labels:
        app: payments-web
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: payments-web
          image: nginx:1.25-alpine
          resources:
            requests: {cpu: 25m, memory: 32Mi}
            limits: {cpu: 50m, memory: 64Mi}
          readinessProbe:
            httpGet:
              path: /
              port: 80
            periodSeconds: 2
            failureThreshold: 2
EOF

kubectl rollout status deployment/payments-web -n "$QUESTION_ID" --timeout=60s

# Step 2: the "someone made two changes at once" regression - reckless
# strategy plus a broken readinessProbe. This is a genuine pod template
# change, so it triggers a new rollout under the new (100%/0%) strategy.
kubectl patch deployment payments-web -n "$QUESTION_ID" --type strategic -p '
{
  "spec": {
    "strategy": {
      "rollingUpdate": {
        "maxUnavailable": "100%",
        "maxSurge": "0%"
      }
    },
    "template": {
      "spec": {
        "containers": [
          {
            "name": "payments-web",
            "readinessProbe": {
              "httpGet": {"path": "/definitely-missing", "port": 80},
              "periodSeconds": 2,
              "failureThreshold": 2
            }
          }
        ]
      }
    }
  }
}'

# Give the bad rollout a little time to actually tear down the old (ready)
# pods before the candidate ever looks at it - otherwise they could arrive
# mid-transition and see a misleadingly-still-healthy state.
sleep 10

echo "setup.sh: $QUESTION_ID ready (outage: availableReplicas should be 0)"
