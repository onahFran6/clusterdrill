#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q109-49-pv-claimref-namespace-mismatch-blocks-binding${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

NS_VALUE="$(kget pv preassigned-pv '{.spec.claimRef.namespace}')"
if [ "$NS_VALUE" = "$QUESTION_ID" ]; then
  FIXED=0
else
  FIXED=1
fi

check_criterion "PV 'preassigned-pv' claimRef.namespace fixed to $QUESTION_ID" \
  [ "$FIXED" = "0" ]

check_criterion "Fix applied AND claimRef.name/capacity/hostPath unchanged" \
  bash -c "[ '$FIXED' = '0' ] && \
    [ \"\$(kubectl get pv preassigned-pv -o jsonpath='{.spec.claimRef.name}')\" = 'preassigned-claim' ] && \
    [ \"\$(kubectl get pv preassigned-pv -o jsonpath='{.spec.capacity.storage}')\" = '100Mi' ] && \
    [ \"\$(kubectl get pv preassigned-pv -o jsonpath='{.spec.hostPath.path}')\" = '/mnt/q109-49-preassigned' ]"

check_criterion "PVC 'preassigned-claim' is Bound to preassigned-pv" \
  bash -c '
    for _ in $(seq 1 15); do
      vol="$(kubectl get pvc preassigned-claim -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.volumeName}" 2>/dev/null)"
      [ "$vol" = "preassigned-pv" ] && exit 0
      sleep 2
    done
    exit 1
  '

print_score
