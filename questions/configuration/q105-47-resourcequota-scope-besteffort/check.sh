#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q105-47-resourcequota-scope-besteffort${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Pod 'extra-worker' exists, Running, and is no longer BestEffort QoS" \
  bash -c '
    phase="$(kubectl get pod extra-worker -n "'"$QUESTION_ID"'" -o jsonpath="{.status.phase}" 2>/dev/null)"
    [ "$phase" = "Running" ] || exit 1
    qos="$(kubectl get pod extra-worker -n "'"$QUESTION_ID"'" -o jsonpath="{.status.qosClass}" 2>/dev/null)"
    [ "$qos" != "BestEffort" ] && [ -n "$qos" ]
  '

# Bundled with extra-worker's existence (rather than standalone) so this
# criterion - which on its own never changes, solved or not - correctly
# contributes to a 0 unsolved score instead of a false-positive partial
# pass before the candidate does anything.
check_criterion "extra-worker got in without disturbing existing-besteffort (still Running/BestEffort) or raising besteffort-quota's hard.pods (still 1)" \
  bash -c '
    ew_phase="$(kubectl get pod extra-worker -n "'"$QUESTION_ID"'" -o jsonpath="{.status.phase}" 2>/dev/null)"
    [ "$ew_phase" = "Running" ] || exit 1
    eb_phase="$(kubectl get pod existing-besteffort -n "'"$QUESTION_ID"'" -o jsonpath="{.status.phase}" 2>/dev/null)"
    [ "$eb_phase" = "Running" ] || exit 1
    eb_qos="$(kubectl get pod existing-besteffort -n "'"$QUESTION_ID"'" -o jsonpath="{.status.qosClass}" 2>/dev/null)"
    [ "$eb_qos" = "BestEffort" ] || exit 1
    hard_pods="$(kubectl get resourcequota besteffort-quota -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.hard.pods}" 2>/dev/null)"
    [ "$hard_pods" = "1" ]
  '

print_score
