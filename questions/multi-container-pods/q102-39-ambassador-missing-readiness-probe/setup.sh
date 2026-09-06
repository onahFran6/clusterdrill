#!/usr/bin/env bash
# Idempotent: creates/resets namespace q102-39-ambassador-missing-readiness-probe
# and seeds a BROKEN Pod. "ambassador" (busybox) proxies TCP connections on
# port 8080 to a backend Service, using socat - but it takes a few seconds
# to install and start listening after the container starts. "app" is the
# main container and is unrelated to the bug. Because "ambassador" has no
# readinessProbe at all, Kubernetes marks it (and therefore the whole Pod,
# once every container reports ready) Ready the instant the container
# process starts - before socat is actually listening on 8080 - so traffic
# sent to the Pod in that early window is refused. The Pod reports 2/2
# Running almost immediately, masking that ambassador briefly was not
# actually ready to serve. Fix: add a readinessProbe to "ambassador" that
# actually waits for port 8080 to be listening.
set -euo pipefail

QUESTION_ID="q102-39-ambassador-missing-readiness-probe${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: ambassador-app
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  containers:
    - name: app
      image: busybox:1.36
      command: ["sh", "-c", "while true; do sleep 3600; done"]
      resources:
        requests:
          cpu: 25m
          memory: 32Mi
        limits:
          cpu: 50m
          memory: 64Mi
    - name: ambassador
      image: busybox:1.36
      command: ["sh", "-c", "sleep 4; nc -lk -p 8080 -e true"]
      ports:
        - containerPort: 8080
      resources:
        requests:
          cpu: 25m
          memory: 32Mi
        limits:
          cpu: 50m
          memory: 64Mi
EOF

echo "setup.sh: $QUESTION_ID ready"
