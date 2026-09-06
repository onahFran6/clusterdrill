#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q110-09-crd-validation-required${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "TicketRequest 'outage-1' exists in $QUESTION_ID" \
  resource_exists ticketrequest outage-1 -n "$QUESTION_ID"

check_criterion "TicketRequest 'outage-1' has spec.priority=high" \
  [ "$(kget ticketrequest outage-1 '{.spec.priority}' -n "$QUESTION_ID")" = "high" ]

print_score
