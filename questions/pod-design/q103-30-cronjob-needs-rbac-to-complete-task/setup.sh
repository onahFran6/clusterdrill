#!/usr/bin/env bash
# Idempotent: creates/resets namespace and seeds a CronJob whose pods run
# under a ServiceAccount that has NO RBAC grant on the ConfigMap it needs
# to patch. The container's actual job is that patch - it detects the
# failed patch explicitly and exits non-zero, so the run visibly Fails
# rather than silently "succeeding" with nothing recorded.
set -euo pipefail

QUESTION_ID="q103-30-cronjob-needs-rbac-to-complete-task${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

# The ConfigMap the CronJob's real task writes to. Starts at a sentinel
# value the container's patch is supposed to overwrite.
kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: job-status
  labels:
    clusterdrill-question: $QUESTION_ID
data:
  last_run_status: "never-run"
EOF

# The identity the CronJob's pods run as. Deliberately given no Role or
# RoleBinding at all - it can authenticate to the API server (it has a
# token), but is authorized for nothing beyond whatever the cluster's
# built-in defaults allow, which does not include patching a ConfigMap.
kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: status-recorder-sa
  labels:
    clusterdrill-question: $QUESTION_ID
EOF

# CronJob whose real job is recording its own completion: patch
# data.last_run_status on job-status via the in-cluster API, using nothing
# but the ServiceAccount token/namespace files kubelet auto-mounts (no
# kubeconfig, no --token flag). backoffLimit: 0 + restartPolicy: Never so a
# forbidden patch fails the Job fast (one pod, one attempt) instead of
# retrying into a slow BackoffLimitExceeded. Schedule is once a day, far
# from "now" in any timezone, purely so the real cron trigger never fires
# during a grading session - every run in this question is triggered
# manually via `kubectl create job --from=cronjob/...`.
#
# NOTE: this heredoc is unquoted (<<EOF, not <<'EOF') so $QUESTION_ID
# interpolates below. Every $ that belongs to the container's OWN embedded
# script (not to this outer setup.sh) is backslash-escaped (\$) so the
# outer shell leaves it alone for the container's shell to expand instead.
kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: batch/v1
kind: CronJob
metadata:
  name: status-recorder
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  schedule: "17 3 * * *"
  jobTemplate:
    metadata:
      labels:
        clusterdrill-question: $QUESTION_ID
    spec:
      backoffLimit: 0
      template:
        metadata:
          labels:
            clusterdrill-question: $QUESTION_ID
        spec:
          serviceAccountName: status-recorder-sa
          restartPolicy: Never
          containers:
            - name: status-recorder
              image: bitnami/kubectl:latest
              command: ["bash", "-c"]
              args:
                - |
                  set -uo pipefail
                  NS="\$(cat /var/run/secrets/kubernetes.io/serviceaccount/namespace)"
                  STATUS="success-\$(date -u +%Y%m%dT%H%M%SZ)"
                  echo "attempting to record \$STATUS in configmap/job-status (namespace \$NS)"
                  if kubectl patch configmap job-status -n "\$NS" --type merge \
                    -p "{\"data\":{\"last_run_status\":\"\$STATUS\"}}"; then
                    echo "recorded \$STATUS in configmap/job-status"
                    exit 0
                  else
                    echo "FATAL: patch of configmap/job-status was rejected - status-recorder-sa" >&2
                    echo "likely lacks RBAC permission (patch/update) on this ConfigMap" >&2
                    exit 1
                  fi
              resources:
                requests:
                  cpu: "25m"
                  memory: "32Mi"
                limits:
                  cpu: "50m"
                  memory: "64Mi"
EOF

# Trigger one run right now so the candidate has real, visible evidence of
# the failure to diagnose (a Failed Job + a 403-flavored log line) instead
# of an abstract "trust us, it's broken." Best-effort only: grading itself
# never depends on this particular Job, only on live state check.sh
# verifies independently, so a slow/unready cluster here just means a less
# polished demo, not a broken gate.
kubectl delete job status-recorder-seed -n "$QUESTION_ID" --ignore-not-found --wait=true >/dev/null 2>&1 || true
kubectl create job status-recorder-seed --from=cronjob/status-recorder -n "$QUESTION_ID" >/dev/null 2>&1 || true
kubectl wait --for=condition=Failed job/status-recorder-seed -n "$QUESTION_ID" --timeout=45s >/dev/null 2>&1 || true

echo "setup.sh: $QUESTION_ID ready"
