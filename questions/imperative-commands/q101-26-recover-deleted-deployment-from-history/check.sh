#!/usr/bin/env bash
# Grades ONLY live cluster state - never a client-supplied "done" flag.
set -uo pipefail

QUESTION_ID="q101-26-recover-deleted-deployment-from-history${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

WORK_DIR="$(question_workdir "$QUESTION_ID")"
SNAPSHOT_FILE="$WORK_DIR/pre-delete-pod-names.txt"

# A just-created/adopted Deployment's availableReplicas can lag a beat
# behind the API server reporting it - poll for a stable "3/3 available"
# state instead of a single snapshot immediately after the candidate's
# command.
deployment_available_3() {
  [ "$(kget deployment catalog-svc '{.status.availableReplicas}' -n "$QUESTION_ID")" = "3" ]
}

# Prove adoption, not a fresh rollout: the exact pod names captured by
# setup.sh before the orphan-delete must still all be present now.
same_pods_still_present() {
  [ -s "$SNAPSHOT_FILE" ] || return 1
  local current_pods
  current_pods="$(kubectl get pods -n "$QUESTION_ID" -l "app=catalog-svc" \
    -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}' 2>/dev/null | sort)"
  local name
  while IFS= read -r name; do
    [ -z "$name" ] && continue
    echo "$current_pods" | grep -qx "$name" || return 1
  done < "$SNAPSHOT_FILE"
  return 0
}

# Right after setup.sh, same_pods_still_present alone would already be true
# (the orphaned pods are untouched) - but no Deployment exists yet at all.
# Bundle both conditions into ONE criterion, polling for a stable result, so
# nothing scores until the candidate has recreated catalog-svc, it has
# actually reached 3/3 available, AND it got there by adopting (not
# replacing) the original pods.
adopted_and_available() {
  local i
  for i in $(seq 1 20); do
    if deployment_available_3 && same_pods_still_present; then
      return 0
    fi
    sleep 3
  done
  return 1
}

check_criterion "Deployment 'catalog-svc' exists with 3/3 available replicas, adopting the original 3 Pods" \
  adopted_and_available

print_score
