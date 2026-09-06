#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q103-16-set-based-label-selector${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

exactly_us_and_eu_are_active() {
  local names
  names="$(kubectl get pods -n "$QUESTION_ID" -l active=true --no-headers 2>/dev/null | awk '{print $1}' | sort | tr '\n' ',')"
  [ "$names" = "svc-eu,svc-us," ]
}

check_criterion "Exactly svc-us and svc-eu are labeled active=true (and no others)" \
  exactly_us_and_eu_are_active

print_score
