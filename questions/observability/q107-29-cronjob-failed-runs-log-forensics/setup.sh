#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q107-29-cronjob-failed-runs-log-forensics${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
kind: ConfigMap
metadata:
  name: cleanup-manifest
  labels:
    clusterdrill-question: $QUESTION_ID
data:
  manifest.txt: cleanup-list-v1
---
apiVersion: batch/v1
kind: CronJob
metadata:
  name: nightly-cleanup
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  schedule: "*/1 * * * *"
  concurrencyPolicy: Forbid
  jobTemplate:
    metadata:
      labels:
        clusterdrill-question: $QUESTION_ID
    spec:
      backoffLimit: 1
      template:
        metadata:
          labels:
            clusterdrill-question: $QUESTION_ID
        spec:
          restartPolicy: Never
          containers:
            - name: nightly-cleanup
              image: busybox:1.36
              # ";" before cat (always run) but "&&" after (only on
              # success) - with all ";" the container would exit 0 via the
              # trailing echo even when cat fails, so the Job would never
              # actually go Failed the way QUESTION.md describes.
              command: ["sh", "-c", "echo starting cleanup; cat /data/manifest.txt && echo done"]
EOF

# Rather than waiting on the real */1 * * * * schedule to tick (slow and,
# on a busy minikube node, not guaranteed to fire twice inside a fixed
# sleep window), trigger two on-demand Jobs from the CronJob's own
# jobTemplate - same broken pod spec, same failure mode, just deterministic
# and fast. This leaves real failed Jobs/Pods with real container logs for
# the candidate to inspect, exactly as if the schedule had fired them.
for i in 1 2; do
  kubectl create job "nightly-cleanup-manual-$i" --from=cronjob/nightly-cleanup -n "$QUESTION_ID" >/dev/null
done

for i in 1 2; do
  kubectl wait --for=condition=Failed "job/nightly-cleanup-manual-$i" -n "$QUESTION_ID" --timeout=60s >/dev/null 2>&1 || true
done

echo "setup.sh: $QUESTION_ID ready"
