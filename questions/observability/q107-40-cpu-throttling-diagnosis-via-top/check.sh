#!/usr/bin/env bash
# No "set -e" - a failed criterion is a normal result, not a script error.
set -uo pipefail

QUESTION_ID="q107-40-cpu-throttling-diagnosis-via-top${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Pod 'number-cruncher' cpu limit raised well above the 10m throttling ceiling (at least 100m), Running, image unchanged" \
  bash -c '
    limit_raw="$(kubectl get pod number-cruncher -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.containers[0].resources.limits.cpu}" 2>/dev/null)"
    case "$limit_raw" in
      *m) limit_m="${limit_raw%m}" ;;
      "") exit 1 ;;
      *) limit_m=$((limit_raw * 1000)) ;;
    esac
    [ "$limit_m" -ge 100 ] 2>/dev/null || exit 1
    phase="$(kubectl get pod number-cruncher -n "'"$QUESTION_ID"'" -o jsonpath="{.status.phase}" 2>/dev/null)"
    [ "$phase" = "Running" ] || exit 1
    image="$(kubectl get pod number-cruncher -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.containers[0].image}" 2>/dev/null)"
    [ "$image" = "busybox:1.36" ]
  '

print_score
