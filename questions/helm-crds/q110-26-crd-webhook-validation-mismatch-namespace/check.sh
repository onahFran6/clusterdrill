#!/usr/bin/env bash
# No "set -e" - a failed criterion is a normal result, not a script error.
set -uo pipefail

QUESTION_ID="q110-26-crd-webhook-validation-mismatch-namespace${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Quota 'team-quota' exists in $QUESTION_ID" \
  resource_exists quota team-quota -n "$QUESTION_ID"

MAX_USERS="$(kget quota team-quota '{.spec.maxUsers}' -n "$QUESTION_ID")"

max_users_within_bounds_and_equals_100() {
  [[ "$MAX_USERS" =~ ^[0-9]+$ ]] || return 1
  [ "$MAX_USERS" -ge 1 ] && [ "$MAX_USERS" -le 100 ] && [ "$MAX_USERS" = "100" ]
}

check_criterion "Quota 'team-quota' spec.maxUsers is within [1,100] and equals 100" \
  max_users_within_bounds_and_equals_100

check_criterion "Quota 'team-quota' spec.tier equals 'gold'" \
  [ "$(kget quota team-quota '{.spec.tier}' -n "$QUESTION_ID")" = "gold" ]

# Confirm the CRD's constraints were NOT loosened: re-attempting the
# original broken values (maxUsers=500, tier=platinum) via a throwaway
# server-side dry-run must still be rejected by the API server. Gated on
# 'team-quota' actually existing first, so this criterion doesn't award a
# free pass in the unsolved state (the CRD itself is never touched by the
# candidate's fix, so in isolation this check is always true).
quota_fixed_and_constraints_intact() {
  resource_exists quota team-quota -n "$QUESTION_ID" || return 1
  [ "$(kget quota team-quota '{.spec.maxUsers}' -n "$QUESTION_ID")" = "100" ] || return 1
  [ "$(kget quota team-quota '{.spec.tier}' -n "$QUESTION_ID")" = "gold" ] || return 1
  kubectl apply --dry-run=server --validate=true -f - >/dev/null 2>&1 <<EOF
apiVersion: limits.clusterdrill.io/v1
kind: Quota
metadata:
  name: team-quota-dryrun-check
  namespace: $QUESTION_ID
spec:
  maxUsers: 500
  tier: platinum
EOF
  [ "$?" -ne 0 ]
}

check_criterion "CRD schema still rejects maxUsers=500/tier=platinum after the fix (constraints not loosened)" \
  quota_fixed_and_constraints_intact

print_score
