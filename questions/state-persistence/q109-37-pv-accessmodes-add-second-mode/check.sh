#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q109-37-pv-accessmodes-add-second-mode${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

MODES="$(kget pv shared-docs-pv '{.spec.accessModes}')"
if echo "$MODES" | grep -q "ReadWriteOnce" && echo "$MODES" | grep -q "ReadOnlyMany"; then
  FIXED=0
else
  FIXED=1
fi

check_criterion "PV 'shared-docs-pv' accessModes now includes both ReadWriteOnce and ReadOnlyMany" \
  [ "$FIXED" = "0" ]

check_criterion "Fix applied AND capacity/hostPath/storageClassName unchanged" \
  bash -c "[ '$FIXED' = '0' ] && \
    [ \"\$(kubectl get pv shared-docs-pv -o jsonpath='{.spec.capacity.storage}')\" = '500Mi' ] && \
    [ \"\$(kubectl get pv shared-docs-pv -o jsonpath='{.spec.hostPath.path}')\" = '/mnt/q109-37-docs' ] && \
    [ \"\$(kubectl get pv shared-docs-pv -o jsonpath='{.spec.storageClassName}')\" = '' ]"

print_score
