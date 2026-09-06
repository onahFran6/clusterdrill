#!/usr/bin/env bash
# No "set -e" - a failed criterion is a normal result, not a script error.
set -uo pipefail

QUESTION_ID="q107-48-shareprocessnamespace-cross-container-visibility${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

# Bundled together - the functional ps check IS the proof
# shareProcessNamespace actually works, not a separate spec-only check.
check_criterion "Pod sets shareProcessNamespace: true, both containers still run their original commands, and 'watchdog' can now see 'main-app's process via ps" \
  bash -c '
    spn="$(kubectl get pod monitored-app -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.shareProcessNamespace}" 2>/dev/null)"
    [ "$spn" = "true" ] || exit 1
    main_running="$(kubectl get pod monitored-app -n "'"$QUESTION_ID"'" -o jsonpath="{.status.containerStatuses[?(@.name==\"main-app\")].ready}" 2>/dev/null)"
    wd_running="$(kubectl get pod monitored-app -n "'"$QUESTION_ID"'" -o jsonpath="{.status.containerStatuses[?(@.name==\"watchdog\")].ready}" 2>/dev/null)"
    [ "$main_running" = "true" ] && [ "$wd_running" = "true" ] || exit 1
    kubectl exec monitored-app -n "'"$QUESTION_ID"'" -c watchdog -- ps 2>/dev/null | grep -q "424242"
  '

print_score
