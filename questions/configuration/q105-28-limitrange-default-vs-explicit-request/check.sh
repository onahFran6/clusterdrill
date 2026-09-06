#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q105-28-limitrange-default-vs-explicit-request${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

# Pod 'bigmem' does not exist until the candidate fixes and applies the
# manifest (setup.sh only seeds the file, never applies it), so "exists"
# alone is already a valid pre-solve-false criterion. Bundled with Running
# to require the fixed manifest actually admits and starts successfully.
check_criterion "Pod 'bigmem' exists and is Running" \
  bash -c '
    phase="$(kubectl get pod bigmem -n "'"$QUESTION_ID"'" -o jsonpath="{.status.phase}" 2>/dev/null)"
    [ "$phase" = "Running" ]
  '

check_criterion "Pod 'bigmem' container memory limit is exactly 200Mi" \
  [ "$(kget pod bigmem '{.spec.containers[0].resources.limits.memory}' -n "$QUESTION_ID")" = "200Mi" ]

check_criterion "Pod 'bigmem' container memory request is exactly 128Mi (matching the LimitRange's default request) AND LimitRange 'container-limits' is unmodified" \
  bash -c '
    req="$(kubectl get pod bigmem -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.containers[0].resources.requests.memory}" 2>/dev/null)"
    [ "$req" = "128Mi" ] || exit 1
    max="$(kubectl get limitrange container-limits -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.limits[0].max.memory}" 2>/dev/null)"
    [ "$max" = "256Mi" ] || exit 1
    defreq="$(kubectl get limitrange container-limits -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.limits[0].defaultRequest.memory}" 2>/dev/null)"
    [ "$defreq" = "128Mi" ]
  '

print_score
