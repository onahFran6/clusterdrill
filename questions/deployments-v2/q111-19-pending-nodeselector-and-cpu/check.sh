#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q111-19-pending-nodeselector-and-cpu${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

# Resolve the real node dynamically - never assume a literal name like
# node01. This appliance may be single-node with an arbitrary name.
RESOLVED_NODE="$(kubectl get nodes -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)"

check_criterion "A schedulable node is labeled disktype=ssd" \
  bash -c '
    label="$(kubectl get node "'"$RESOLVED_NODE"'" -o jsonpath="{.metadata.labels.disktype}" 2>/dev/null)"
    [ "$label" = "ssd" ]
  '

check_criterion "Deployment keeps nodeSelector disktype=ssd and requests cpu=250m" \
  bash -c '
    selector="$(kubectl get deployment press -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.nodeSelector.disktype}" 2>/dev/null)"
    cpu="$(kubectl get deployment press -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.containers[0].resources.requests.cpu}" 2>/dev/null)"
    [ "$selector" = "ssd" ] && [ "$cpu" = "250m" ]
  '

check_criterion "All 3 pods are Ready and scheduled on the fast-disk node" \
  bash -c '
    ready="$(kubectl get deployment press -n "'"$QUESTION_ID"'" -o jsonpath="{.status.readyReplicas}" 2>/dev/null)"
    [ "$ready" = "3" ] || exit 1
    nodes="$(kubectl get pods -n "'"$QUESTION_ID"'" -l app=press -o jsonpath="{range .items[*]}{.spec.nodeName}{\"\n\"}{end}" 2>/dev/null | sort -u)"
    [ "$nodes" = "'"$RESOLVED_NODE"'" ]
  '

print_score
