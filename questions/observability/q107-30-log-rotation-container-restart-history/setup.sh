#!/usr/bin/env bash
# Idempotent: creates/resets namespace and seeds a pod whose container
# tracks its own start count on an emptyDir volume, crashing (exit 1) on
# its first two starts and then succeeding and sleeping on the third - so
# the *current* container's logs show "run number 3" / "migration
# complete" while `kubectl logs --previous` shows "run number 2" /
# "fatal: dependency unavailable".
set -euo pipefail

QUESTION_ID="q107-30-log-rotation-container-restart-history${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: flaky-migrator
  labels:
    app: flaky-migrator
    clusterdrill-question: $QUESTION_ID
spec:
  restartPolicy: Always
  containers:
    - name: flaky-migrator
      image: busybox:1.36
      command:
        - sh
        - -c
        - |
          n=\$(cat /state/count 2>/dev/null || echo 0)
          n=\$((n+1))
          echo \$n > /state/count
          echo "run number \$n"
          if [ "\$n" -lt 3 ]; then
            echo "fatal: dependency unavailable" >&2
            exit 1
          else
            echo "migration complete"
            sleep 3600
          fi
      volumeMounts:
        - name: state
          mountPath: /state
  volumes:
    - name: state
      emptyDir: {}
EOF

# Wait until the pod has crashed twice (restartCount >= 2) and the
# container is finally Ready on its third start, so both the "current"
# and "--previous" log streams the candidate needs are actually available.
for _ in $(seq 1 40); do
  restarts="$(kubectl get pod flaky-migrator -n "$QUESTION_ID" -o jsonpath='{.status.containerStatuses[0].restartCount}' 2>/dev/null || echo 0)"
  ready="$(kubectl get pod flaky-migrator -n "$QUESTION_ID" -o jsonpath='{.status.containerStatuses[0].ready}' 2>/dev/null || echo false)"
  if [[ "${restarts:-0}" -ge 2 && "$ready" == "true" ]]; then
    break
  fi
  sleep 3
done
kubectl wait --for=condition=Ready pod/flaky-migrator -n "$QUESTION_ID" --timeout=90s || true

# Clean up any pre-existing diagnosis file from a previous run of this question.
WORK_DIR="$(question_workdir "$QUESTION_ID")"
rm -f "$WORK_DIR/migrator-diagnosis.txt"

echo "setup.sh: $QUESTION_ID ready"
