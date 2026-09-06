#!/usr/bin/env bash
# No "set -e" - a failed criterion is a normal result, not a script error.
set -uo pipefail

QUESTION_ID="q107-42-nodeselector-mismatch-blocks-scheduling${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Pod 'report-worker' no longer has an unsatisfiable nodeSelector, is Running, and image is unchanged" \
  bash -c '
    ns_val="$(kubectl get pod report-worker -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.nodeSelector.disktype}" 2>/dev/null)"
    [ -z "$ns_val" ] || exit 1
    phase="$(kubectl get pod report-worker -n "'"$QUESTION_ID"'" -o jsonpath="{.status.phase}" 2>/dev/null)"
    [ "$phase" = "Running" ] || exit 1
    image="$(kubectl get pod report-worker -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.containers[0].image}" 2>/dev/null)"
    [ "$image" = "nginx:1.25-alpine" ]
  '

print_score
