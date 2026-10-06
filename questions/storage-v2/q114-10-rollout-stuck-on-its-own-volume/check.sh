#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q114-10-rollout-stuck-on-its-own-volume${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Deployment ledger uses strategy Recreate" \
  bash -c '[ "$(kubectl get deployment ledger -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.strategy.type}" 2>/dev/null)" = "Recreate" ]'

# Bundled on purpose: in the unsolved state the Deployment already reports
# 1/1 ready (the OLD pod, still on busybox:1.36) - readyReplicas alone would
# trivially pass before any real fix. Only the combination of "ready" AND
# "running busybox:1.37" proves the upgrade actually completed.
check_criterion "Deployment ledger is 1/1 ready and the one live pod runs busybox:1.37 (not the old 1.36)" \
  bash -c '
    for i in $(seq 1 10); do
      total="$(kubectl get deployment ledger -n "'"$QUESTION_ID"'" -o jsonpath="{.status.replicas}" 2>/dev/null)"
      ready="$(kubectl get deployment ledger -n "'"$QUESTION_ID"'" -o jsonpath="{.status.readyReplicas}" 2>/dev/null)"
      updated="$(kubectl get deployment ledger -n "'"$QUESTION_ID"'" -o jsonpath="{.status.updatedReplicas}" 2>/dev/null)"
      pod_count="$(kubectl get pods -n "'"$QUESTION_ID"'" -l app=ledger --no-headers 2>/dev/null | wc -l | tr -d " ")"
      image="$(kubectl get pods -n "'"$QUESTION_ID"'" -l app=ledger -o jsonpath="{.items[0].spec.containers[0].image}" 2>/dev/null)"
      ready_image="$(kubectl get pods -n "'"$QUESTION_ID"'" -l app=ledger -o jsonpath="{.items[0].status.containerStatuses[0].ready}" 2>/dev/null)"
      if [ "$total" = "1" ] && [ "$ready" = "1" ] && [ "$updated" = "1" ] && [ "$pod_count" = "1" ] \
        && [ "$image" = "busybox:1.37" ] && [ "$ready_image" = "true" ]; then
        exit 0
      fi
      sleep 3
    done
    exit 1
  '

print_score
