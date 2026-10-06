#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q111-17-immutable-selector-replace${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Annotation owner=payments is present" \
  [ "$(kget deployment wallet '{.metadata.annotations.owner}' -n "$QUESTION_ID")" = "payments" ]

check_criterion "Selector and pod template both carry label team=fortuna" \
  bash -c '
    sel="$(kubectl get deployment wallet -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.selector.matchLabels.team}" 2>/dev/null)"
    tmpl="$(kubectl get deployment wallet -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.metadata.labels.team}" 2>/dev/null)"
    [ "$sel" = "fortuna" ] && [ "$tmpl" = "fortuna" ]
  '

check_criterion "2 pods are running with the new selector" \
  bash -c '
    team="$(kubectl get deployment wallet -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.selector.matchLabels.team}" 2>/dev/null)"
    ready="$(kubectl get deployment wallet -n "'"$QUESTION_ID"'" -o jsonpath="{.status.readyReplicas}" 2>/dev/null)"
    [ "$team" = "fortuna" ] && [ "$ready" = "2" ]
  '

check_criterion "Delete+recreate reset the rollout history (revision 1)" \
  bash -c '
    team="$(kubectl get deployment wallet -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.selector.matchLabels.team}" 2>/dev/null)"
    revision="$(kubectl get deployment wallet -n "'"$QUESTION_ID"'" -o jsonpath="{.metadata.annotations.deployment\.kubernetes\.io/revision}" 2>/dev/null)"
    [ "$team" = "fortuna" ] && [ "$revision" = "1" ]
  '

print_score
