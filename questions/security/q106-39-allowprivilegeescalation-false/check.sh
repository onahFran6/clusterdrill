#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q106-39-allowprivilegeescalation-false${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

# Bundled with allowPrivilegeEscalation itself (not standalone) - Running +
# unchanged image are already true straight out of setup.sh, so checking
# only those would be vacuously true before the candidate does anything.
check_criterion "Pod 'web-worker' has allowPrivilegeEscalation=false, is Running, and still uses nginx:1.25-alpine" \
  bash -c '
    ape="$(kubectl get pod web-worker -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.containers[0].securityContext.allowPrivilegeEscalation}" 2>/dev/null)"
    [ "$ape" = "false" ] || exit 1
    phase="$(kubectl get pod web-worker -n "'"$QUESTION_ID"'" -o jsonpath="{.status.phase}" 2>/dev/null)"
    [ "$phase" = "Running" ] || exit 1
    image="$(kubectl get pod web-worker -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.containers[0].image}" 2>/dev/null)"
    [ "$image" = "nginx:1.25-alpine" ]
  '

print_score
