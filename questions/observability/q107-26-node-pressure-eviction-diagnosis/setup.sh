#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q107-26-node-pressure-eviction-diagnosis${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

# Real node-pressure eviction is not deterministic enough for a lab/CI
# minikube node, so we seed the pod directly in the terminal state a real
# DiskPressure eviction would leave behind: create the pod with a command
# that runs the real 800Mi dd fill and then exits on its own (standing in
# for "already ran the fill and finished" - no sleep tail here, unlike the
# candidate-facing description, purely so the container reaches a genuine
# terminal state on its own within a few seconds), wait for that terminal
# phase, then patch the status subresource to Evicted. Patching *before*
# the container naturally exits races the kubelet's own status sync (which
# keeps overwriting phase/reason while the container is still live) -
# waiting for a real terminal phase first avoids that race.
kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: log-spooler
  labels:
    app: log-spooler
    clusterdrill-question: $QUESTION_ID
spec:
  restartPolicy: Never
  containers:
    - name: log-spooler
      image: busybox:1.36
      command: ["sh", "-c", "dd if=/dev/zero of=/scratch/fill.img bs=1M count=800"]
      volumeMounts:
        - name: scratch
          mountPath: /scratch
  volumes:
    - name: scratch
      emptyDir: {}
EOF

for _ in $(seq 1 60); do
  phase="$(kubectl get pod log-spooler -n "$QUESTION_ID" -o jsonpath='{.status.phase}' 2>/dev/null || true)"
  if [[ "$phase" == "Failed" || "$phase" == "Succeeded" ]]; then
    break
  fi
  sleep 1
done

kubectl patch pod log-spooler -n "$QUESTION_ID" --subresource=status --type=merge -p \
  '{"status":{"phase":"Failed","reason":"Evicted","message":"The node was low on resource: ephemeral-storage. Container log-spooler was using 800Mi, which exceeds its request of 0."}}' \
  >/dev/null

echo "setup.sh: $QUESTION_ID ready (log-spooler pre-seeded as Evicted)"
