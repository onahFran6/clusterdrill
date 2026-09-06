#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q109-40-pvc-stuck-terminating-pod-still-attached${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Pod 'session-worker' deleted" \
  bash -c "! kubectl get pod session-worker -n '$QUESTION_ID' >/dev/null 2>&1"

check_criterion "PVC 'session-cache' finalizer cleared and it actually finished deleting" \
  bash -c '
    for _ in $(seq 1 15); do
      kubectl get pvc session-cache -n "'"$QUESTION_ID"'" >/dev/null 2>&1 || exit 0
      sleep 2
    done
    exit 1
  '

print_score
