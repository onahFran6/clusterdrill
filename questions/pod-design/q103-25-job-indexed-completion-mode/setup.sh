#!/usr/bin/env bash
# Idempotent: creates/resets namespace and seeds a broken indexed-write Job.
set -euo pipefail

QUESTION_ID="q103-25-job-indexed-completion-mode${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

# Shared storage the Job's pods write to and check.sh later inspects from
# outside those pods (Job pods don't share a filesystem with each other or
# with check.sh by default, and a Never-restart pod that already exited
# can't be kubectl exec'd into). This cluster is single-node minikube with
# the default StorageClass "standard" (k8s.io/minikube-hostpath, Immediate
# binding), so a ReadWriteOnce PVC binds immediately and every Job pod -
# all scheduled on the same lone node - can mount it concurrently: RWO
# restricts a volume to one *node*, not one pod.
kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: shared-output
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
EOF

kubectl wait --for=jsonpath='{.status.phase}'=Bound pvc/shared-output -n "$QUESTION_ID" --timeout=60s || true

# Belt-and-braces idempotency: setup.sh must be safe to re-run standalone
# (not just via full_reset) without accumulating duplicates or leaving a
# stray file from a previous partial run under the shared PVC that could
# skew check.sh's file-content assertions later.
kubectl delete job indexed-writer -n "$QUESTION_ID" --ignore-not-found --wait=true >/dev/null 2>&1

kubectl delete pod output-cleanup -n "$QUESTION_ID" --ignore-not-found --wait=true >/dev/null 2>&1
kubectl run output-cleanup -n "$QUESTION_ID" --image=busybox:1.36 --restart=Never \
  --overrides='{
    "metadata": {"labels": {"clusterdrill-question": "'"$QUESTION_ID"'"}},
    "spec": {
      "containers": [{
        "name": "output-cleanup",
        "image": "busybox:1.36",
        "command": ["sh", "-c", "rm -rf /data/* 2>/dev/null; exit 0"],
        "volumeMounts": [{"name": "shared", "mountPath": "/data"}],
        "resources": {"requests": {"cpu": "25m", "memory": "32Mi"}, "limits": {"cpu": "50m", "memory": "64Mi"}}
      }],
      "volumes": [{"name": "shared", "persistentVolumeClaim": {"claimName": "shared-output"}}]
    }
  }' >/dev/null
kubectl wait --for=jsonpath='{.status.phase}'=Succeeded pod/output-cleanup -n "$QUESTION_ID" --timeout=60s >/dev/null 2>&1 || true
kubectl delete pod output-cleanup -n "$QUESTION_ID" --ignore-not-found --wait=true >/dev/null 2>&1

# The broken Job: `spec.completionMode` is left unset, so the API server
# defaults it to "NonIndexed". In NonIndexed mode Kubernetes never injects
# JOB_COMPLETION_INDEX into any pod, so it expands to an empty string
# below - all 3 pods end up writing/overwriting the SAME file
# (/data/output-.txt) instead of each writing its own distinct
# /data/output-<index>.txt. .spec.completions and .spec.parallelism are
# already correctly set to 3; only completionMode needs fixing (and, since
# it's immutable, the Job needs deleting and recreating to fix it).
#
# NOTE: this heredoc is intentionally UNQUOTED (<<EOF, not <<'EOF') because
# $QUESTION_ID inside it must be expanded by this outer shell. That means
# every reference to the container's own JOB_COMPLETION_INDEX variable
# below MUST be escaped as \${JOB_COMPLETION_INDEX} - otherwise the outer
# shell would substitute it too (as an unset outer variable, silently
# collapsing to an empty string before the container ever sees it).
kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: batch/v1
kind: Job
metadata:
  name: indexed-writer
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  completions: 3
  parallelism: 3
  template:
    metadata:
      labels:
        clusterdrill-question: $QUESTION_ID
    spec:
      restartPolicy: Never
      containers:
        - name: writer
          image: busybox:1.36
          command: ["sh", "-c", "echo \"\${JOB_COMPLETION_INDEX}\" > /data/output-\${JOB_COMPLETION_INDEX}.txt; sleep 2"]
          volumeMounts:
            - name: shared
              mountPath: /data
          resources:
            requests:
              cpu: 25m
              memory: 32Mi
            limits:
              cpu: 50m
              memory: 64Mi
      volumes:
        - name: shared
          persistentVolumeClaim:
            claimName: shared-output
EOF

echo "setup.sh: $QUESTION_ID ready"
