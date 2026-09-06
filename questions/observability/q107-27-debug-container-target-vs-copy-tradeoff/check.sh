#!/usr/bin/env bash
# No "set -e" - a failed criterion is a normal result, not a script error.
set -uo pipefail

QUESTION_ID="q107-27-debug-container-target-vs-copy-tradeoff${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Debug copy pod 'worker-proc-debug' exists" \
  resource_exists pod worker-proc-debug -n "$QUESTION_ID"

check_criterion "'worker-proc-debug' has shareProcessNamespace=true" \
  [ "$(kget pod worker-proc-debug '{.spec.shareProcessNamespace}' -n "$QUESTION_ID")" = "true" ]

copy_images="$(kget pod worker-proc-debug '{.spec.containers[*].image}' -n "$QUESTION_ID")"
all_busybox="true"
if [ -z "$copy_images" ]; then
  all_busybox="false"
else
  for img in $copy_images; do
    if [ "$img" != "busybox:1.36" ]; then
      all_busybox="false"
    fi
  done
fi

check_criterion "Every container in 'worker-proc-debug' uses image busybox:1.36" \
  [ "$all_busybox" = "true" ]

# Bundled into one criterion (rather than three independent ones) so that
# the original pod's steady-state - which is already true immediately
# after setup.sh, before the candidate does anything - can't award points
# on its own. It only counts once a debug copy actually exists, proving
# the candidate solved the task via a copy rather than mutating the
# original pod in place.
original_exists="false"
resource_exists pod worker-proc -n "$QUESTION_ID" && original_exists="true"

original_share_pns="$(kget pod worker-proc '{.spec.shareProcessNamespace}' -n "$QUESTION_ID")"
original_phase="$(kget pod worker-proc '{.status.phase}' -n "$QUESTION_ID")"

check_criterion "Debug copy exists AND original pod 'worker-proc' is untouched (exists, Running, shareProcessNamespace still unset)" \
  bash -c '[ "$1" = "true" ] && [ "$2" = "true" ] && [ -z "$3" ] && [ "$4" = "Running" ]' _ \
  "$(resource_exists pod worker-proc-debug -n "$QUESTION_ID" && echo true || echo false)" \
  "$original_exists" "$original_share_pns" "$original_phase"

print_score
