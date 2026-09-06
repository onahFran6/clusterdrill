#!/usr/bin/env bash
# No "set -e" - a failed criterion is a normal result, not a script error.
set -uo pipefail

QUESTION_ID="q107-38-startupprobe-never-succeeds-blocks-liveness${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

# Bundled together - Ready=true only becomes possible once startupProbe can
# actually succeed, so this is the functional proof of the fix, not a
# separate vacuous check.
check_criterion "Pod 'slow-starter' startupProbe now targets a path that actually succeeds, livenessProbe/readinessProbe paths unchanged, and the Pod is Ready" \
  bash -c '
    sp_path="$(kubectl get pod slow-starter -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.containers[0].startupProbe.httpGet.path}" 2>/dev/null)"
    [ "$sp_path" != "/this-path-does-not-exist" ] && [ -n "$sp_path" ] || exit 1
    lp_path="$(kubectl get pod slow-starter -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.containers[0].livenessProbe.httpGet.path}" 2>/dev/null)"
    [ "$lp_path" = "/" ] || exit 1
    rp_path="$(kubectl get pod slow-starter -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.containers[0].readinessProbe.httpGet.path}" 2>/dev/null)"
    [ "$rp_path" = "/" ] || exit 1
    ready="$(kubectl get pod slow-starter -n "'"$QUESTION_ID"'" -o jsonpath="{.status.conditions[?(@.type==\"Ready\")].status}" 2>/dev/null)"
    [ "$ready" = "True" ]
  '

print_score
