#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q114-16-deleted-while-in-use${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "PVC data no longer exists (finalizer finally cleared)" \
  bash -c '! kubectl get pvc data -n "'"$QUESTION_ID"'" >/dev/null 2>&1'

check_criterion "The PV this question provisioned survived: Retain, Released" \
  bash -c '
    pv_name="$(kubectl get pv -l clusterdrill-question="'"$QUESTION_ID"'" -o jsonpath="{.items[0].metadata.name}" 2>/dev/null)"
    [ -n "$pv_name" ] || exit 1
    policy="$(kubectl get pv "$pv_name" -o jsonpath="{.spec.persistentVolumeReclaimPolicy}" 2>/dev/null)"
    phase="$(kubectl get pv "$pv_name" -o jsonpath="{.status.phase}" 2>/dev/null)"
    [ "$policy" = "Retain" ] && [ "$phase" = "Released" ]
  '

print_score
