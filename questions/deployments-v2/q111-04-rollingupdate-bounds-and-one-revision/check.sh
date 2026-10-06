#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q111-04-rollingupdate-bounds-and-one-revision${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Strategy keeps at least 9 available, never more than 12 (maxUnavailable=1, maxSurge=2)" \
  bash -c '
    max_unavail="$(kubectl get deployment relay -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.strategy.rollingUpdate.maxUnavailable}" 2>/dev/null)"
    max_surge="$(kubectl get deployment relay -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.strategy.rollingUpdate.maxSurge}" 2>/dev/null)"
    [ "$max_unavail" = "1" ] && [ "$max_surge" = "2" ]
  '

check_criterion "Deployment runs image nginx:1.27" \
  [ "$(kget deployment relay '{.spec.template.spec.containers[0].image}' -n "$QUESTION_ID")" = "nginx:1.27" ]

check_criterion "Env var FEATURE_X=on is set" \
  bash -c '
    value="$(kubectl get deployment relay -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.containers[0].env[?(@.name==\"FEATURE_X\")].value}" 2>/dev/null)"
    [ "$value" = "on" ]
  '

check_criterion "Image and env landed as exactly one new revision (revision 2)" \
  [ "$(kget deployment relay '{.metadata.annotations.deployment\.kubernetes\.io/revision}' -n "$QUESTION_ID")" = "2" ]

check_criterion "Change-cause annotation is 'relay 1.27 + feature x'" \
  [ "$(kget deployment relay '{.metadata.annotations.kubernetes\.io/change-cause}' -n "$QUESTION_ID")" = "relay 1.27 + feature x" ]

print_score
