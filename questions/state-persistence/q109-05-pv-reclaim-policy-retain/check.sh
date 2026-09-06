#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q109-05-pv-reclaim-policy-retain${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "PersistentVolume 'q109-05-audit-pv' reclaim policy is Retain" \
  [ "$(kget pv q109-05-audit-pv '{.spec.persistentVolumeReclaimPolicy}')" = "Retain" ]

print_score
