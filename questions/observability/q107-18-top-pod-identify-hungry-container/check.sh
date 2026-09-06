#!/usr/bin/env bash
# No "set -e" - a failed criterion is a normal result, not a script error.
set -uo pipefail

QUESTION_ID="q107-18-top-pod-identify-hungry-container${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "burner pod is labeled role=cpu-hog" \
  bash -c "[[ \"\$(kubectl get pod burner -n '$QUESTION_ID' -o jsonpath='{.metadata.labels.role}' 2>/dev/null)\" == 'cpu-hog' ]]"

check_criterion "only burner is labeled role=cpu-hog (quiet-a/quiet-b untouched)" \
  bash -c "
    burner_role=\"\$(kubectl get pod burner -n '$QUESTION_ID' -o jsonpath='{.metadata.labels.role}' 2>/dev/null)\"
    a_role=\"\$(kubectl get pod quiet-a -n '$QUESTION_ID' -o jsonpath='{.metadata.labels.role}' 2>/dev/null)\"
    b_role=\"\$(kubectl get pod quiet-b -n '$QUESTION_ID' -o jsonpath='{.metadata.labels.role}' 2>/dev/null)\"
    [[ \"\$burner_role\" == 'cpu-hog' && \"\$a_role\" != 'cpu-hog' && \"\$b_role\" != 'cpu-hog' ]]
  "

print_score
