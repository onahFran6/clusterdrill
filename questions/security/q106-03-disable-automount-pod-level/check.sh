#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q106-03-disable-automount-pod-level${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Pod 'static-renderer' has automountServiceAccountToken=false" \
  [ "$(kget pod static-renderer '{.spec.automountServiceAccountToken}' -n "$QUESTION_ID")" = "false" ]

print_score
