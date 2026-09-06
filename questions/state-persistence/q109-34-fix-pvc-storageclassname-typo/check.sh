#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q109-34-fix-pvc-storageclassname-typo${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

SC_NAME="$(kget pvc reports-data '{.spec.storageClassName}' -n "$QUESTION_ID")"
if [ "$SC_NAME" = "standard" ]; then
  FIXED=0
else
  FIXED=1
fi

check_criterion "PVC 'reports-data' storageClassName fixed to 'standard'" \
  [ "$FIXED" = "0" ]

check_criterion "PVC 'reports-data' is Bound" \
  bash -c '
    for _ in $(seq 1 15); do
      phase="$(kubectl get pvc reports-data -n "'"$QUESTION_ID"'" -o jsonpath="{.status.phase}" 2>/dev/null)"
      [ "$phase" = "Bound" ] && exit 0
      sleep 2
    done
    exit 1
  '

check_criterion "Fix applied AND PVC 'reports-data' still requests 100Mi with access mode ReadWriteOnce" \
  bash -c "[ '$FIXED' = '0' ] && \
    [ \"\$(kubectl get pvc reports-data -n '$QUESTION_ID' -o jsonpath='{.spec.resources.requests.storage}')\" = '100Mi' ] && \
    [ \"\$(kubectl get pvc reports-data -n '$QUESTION_ID' -o jsonpath='{.spec.accessModes[0]}')\" = 'ReadWriteOnce' ]"

print_score
