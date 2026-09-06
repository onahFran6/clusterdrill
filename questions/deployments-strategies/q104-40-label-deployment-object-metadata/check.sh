#!/usr/bin/env bash
# No "set -e" - a failed criterion is a normal result, not a script error.
set -uo pipefail

QUESTION_ID="q104-40-label-deployment-object-metadata${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Deployment 'notifications' object metadata has team=growth" \
  [ "$(kget deployment notifications '{.metadata.labels.team}' -n "$QUESTION_ID")" = "growth" ]

# Gated on the object-metadata label too (not just the pod-template absence
# and readiness) - both of those are already true straight out of setup.sh,
# so checking only them would be vacuously true before the candidate does
# anything (false positive).
check_criterion "Pod template labels are unchanged (no 'team' key there) and both replicas still Ready" \
  bash -c '
    object_team="$(kubectl get deployment notifications -n "'"$QUESTION_ID"'" -o jsonpath="{.metadata.labels.team}" 2>/dev/null)"
    [ "$object_team" = "growth" ] || exit 1
    template_team="$(kubectl get deployment notifications -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.metadata.labels.team}" 2>/dev/null)"
    [ -z "$template_team" ] || exit 1
    ready="$(kubectl get deployment notifications -n "'"$QUESTION_ID"'" -o jsonpath="{.status.readyReplicas}" 2>/dev/null)"
    [ "$ready" = "2" ]
  '

print_score
