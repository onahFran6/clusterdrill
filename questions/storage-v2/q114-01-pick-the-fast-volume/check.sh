#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e` - see lib/grading.sh header.
set -uo pipefail

QUESTION_ID="q114-01-pick-the-fast-volume${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "PVC nile-data selects tier=fast, class manual-q114-01" \
  bash -c '
    sel="$(kubectl get pvc nile-data -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.selector.matchLabels.tier}" 2>/dev/null)"
    sc="$(kubectl get pvc nile-data -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.storageClassName}" 2>/dev/null)"
    [ "$sel" = "fast" ] && [ "$sc" = "manual-q114-01" ]
  '

check_criterion "PVC nile-data is Bound to q114-01-fast-pv (proves the selector, not luck, picked it)" \
  bash -c '
    phase="$(kubectl get pvc nile-data -n "'"$QUESTION_ID"'" -o jsonpath="{.status.phase}" 2>/dev/null)"
    vol="$(kubectl get pvc nile-data -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.volumeName}" 2>/dev/null)"
    [ "$phase" = "Bound" ] && [ "$vol" = "q114-01-fast-pv" ]
  '

check_criterion "Pod nile-app is Running" \
  bash -c '[ "$(kubectl get pod nile-app -n "'"$QUESTION_ID"'" -o jsonpath="{.status.phase}" 2>/dev/null)" = "Running" ]'

check_criterion "nile-app's /data/msg reads 'hello nile'" \
  bash -c 'kubectl exec nile-app -n "'"$QUESTION_ID"'" -- cat /data/msg 2>/dev/null | grep -q "hello nile"'

print_score
