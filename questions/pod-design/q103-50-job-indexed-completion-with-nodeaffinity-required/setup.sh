#!/usr/bin/env bash
# Idempotent: creates/resets namespace q103-50-job-indexed-completion-with-nodeaffinity-required
# and writes an incomplete Job manifest (missing completionMode: Indexed AND
# .spec.template.spec.affinity.nodeAffinity entirely) to this question's terminal working
# directory. Never applied here - both missing fields are immutable once a Job exists, so the
# unsolved state has NO Job object at all (mirrors the q103-23/q103-39 precedent for "unapplied
# manifest" questions).

set -euo pipefail

QUESTION_ID="q103-50-job-indexed-completion-with-nodeaffinity-required${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

WORK_DIR="$(question_workdir "$QUESTION_ID")"
cat > "$WORK_DIR/sharded-worker.yaml" <<EOF
apiVersion: batch/v1
kind: Job
metadata:
  name: sharded-worker
  namespace: $QUESTION_ID
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  completions: 3
  parallelism: 3
  # TODO: add completionMode: Indexed here (sibling of completions/parallelism)
  template:
    metadata:
      labels:
        clusterdrill-question: $QUESTION_ID
    spec:
      # TODO: add affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution
      # matching kubernetes.io/hostname In [<this cluster's actual node name>]
      # (find it with: kubectl get nodes -o name)
      restartPolicy: Never
      containers:
        - name: sharded-worker
          image: busybox:1.36
          command: ["sh", "-c", "echo \"index \$JOB_COMPLETION_INDEX\""]
          resources:
            requests:
              cpu: 25m
              memory: 32Mi
            limits:
              cpu: 50m
              memory: 64Mi
EOF

echo "setup.sh: $QUESTION_ID ready (incomplete manifest at $WORK_DIR/sharded-worker.yaml, not yet applied)"
