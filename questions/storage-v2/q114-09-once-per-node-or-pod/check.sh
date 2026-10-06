#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q114-09-once-per-node-or-pod${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "c-rwo Bound to q114-09-rwo, c-rwop Bound to q114-09-rwop" \
  bash -c '
    p1="$(kubectl get pvc c-rwo -n "'"$QUESTION_ID"'" -o jsonpath="{.status.phase}" 2>/dev/null)"
    v1="$(kubectl get pvc c-rwo -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.volumeName}" 2>/dev/null)"
    p2="$(kubectl get pvc c-rwop -n "'"$QUESTION_ID"'" -o jsonpath="{.status.phase}" 2>/dev/null)"
    v2="$(kubectl get pvc c-rwop -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.volumeName}" 2>/dev/null)"
    [ "$p1" = "Bound" ] && [ "$v1" = "q114-09-rwo" ] && [ "$p2" = "Bound" ] && [ "$v2" = "q114-09-rwop" ]
  '

check_criterion "a1 and a2 (sharing the RWO claim on the same node) are both Running" \
  bash -c '
    for i in $(seq 1 12); do
      s1="$(kubectl get pod a1 -n "'"$QUESTION_ID"'" -o jsonpath="{.status.phase}" 2>/dev/null)"
      s2="$(kubectl get pod a2 -n "'"$QUESTION_ID"'" -o jsonpath="{.status.phase}" 2>/dev/null)"
      [ "$s1" = "Running" ] && [ "$s2" = "Running" ] && exit 0
      sleep 5
    done
    exit 1
  '

check_criterion "b1 (the first RWOP consumer) is Running" \
  bash -c '[ "$(kubectl get pod b1 -n "'"$QUESTION_ID"'" -o jsonpath="{.status.phase}" 2>/dev/null)" = "Running" ]'

check_criterion "b2 (the second RWOP consumer) is stuck Pending - RWOP allows only one pod cluster-wide" \
  bash -c '[ "$(kubectl get pod b2 -n "'"$QUESTION_ID"'" -o jsonpath="{.status.phase}" 2>/dev/null)" = "Pending" ]'

print_score
