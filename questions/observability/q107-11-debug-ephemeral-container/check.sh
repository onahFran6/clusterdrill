#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q107-11-debug-ephemeral-container${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Ephemeral container is named 'debugger'" \
  [ "$(kget pod payments-api '{.spec.ephemeralContainers[0].name}' -n "$QUESTION_ID")" = "debugger" ]

check_criterion "Ephemeral container uses image busybox:1.36" \
  [ "$(kget pod payments-api '{.spec.ephemeralContainers[0].image}' -n "$QUESTION_ID")" = "busybox:1.36" ]

check_criterion "Ephemeral container targets the payments-api container" \
  [ "$(kget pod payments-api '{.spec.ephemeralContainers[0].targetContainerName}' -n "$QUESTION_ID")" = "payments-api" ]

print_score
