#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q104-18-scale-during-rollout${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Deployment 'media-transcoder' spec.replicas is 8" \
  [ "$(kget deployment media-transcoder '{.spec.replicas}' -n "$QUESTION_ID")" = "8" ]

check_criterion "Combined pod count across media-transcoder's ReplicaSets reached the new total (8, plus at most maxSurge headroom)" \
  bash -c '
    total="$(kubectl get rs -n "'"$QUESTION_ID"'" -l app=media-transcoder -o jsonpath="{.items[*].spec.replicas}" 2>/dev/null | tr " " "+" )"
    total="${total:-0}"
    sum=$(( ${total} ))
    # Default maxSurge is 25%% of 8 = 2, so the controller may legitimately
    # keep the combined old+new ReplicaSet total above 8 while the new
    # ReplicaSet cannot reach Available (stuck on the broken probe).
    [ "$sum" -ge 8 ] && [ "$sum" -le 10 ]
  '

check_criterion "The rollout is still stuck on the broken probe (image/probe untouched)" \
  bash -c '
    image="$(kubectl get deployment media-transcoder -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.containers[0].image}" 2>/dev/null)"
    path="$(kubectl get deployment media-transcoder -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.containers[0].readinessProbe.httpGet.path}" 2>/dev/null)"
    replicas="$(kubectl get deployment media-transcoder -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.replicas}" 2>/dev/null)"
    [ "$image" = "nginx:1.25-alpine" ] && [ "$path" = "/does-not-exist" ] && [ "$replicas" = "8" ]
  '

print_score
