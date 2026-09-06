#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q104-07-pause-rollout-mid-update${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Deployment 'notifications' is paused" \
  [ "$(kget deployment notifications '{.spec.paused}' -n "$QUESTION_ID")" = "true" ]

check_criterion "Deployment 'notifications' desired template image is nginx:1.25-alpine" \
  [ "$(kget deployment notifications '{.spec.template.spec.containers[0].image}' -n "$QUESTION_ID")" = "nginx:1.25-alpine" ]

check_criterion "Live pods still run the old image nginx:1.24-alpine (rollout did not proceed while paused)" \
  bash -c '
    paused="$(kubectl get deployment notifications -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.paused}" 2>/dev/null)"
    running_old="$(kubectl get pods -n "'"$QUESTION_ID"'" -l app=notifications -o jsonpath="{range .items[*]}{.spec.containers[0].image}{\"\n\"}{end}" 2>/dev/null | grep -c "nginx:1.24-alpine")"
    [ "$paused" = "true" ] && [ "$running_old" = "4" ]
  '

check_criterion "Desired image changed to 1.25 but no new ReplicaSet has scaled up for it" \
  bash -c '
    desired="$(kubectl get deployment notifications -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.containers[0].image}" 2>/dev/null)"
    new_rs_replicas="$(kubectl get rs -n "'"$QUESTION_ID"'" -o jsonpath="{range .items[*]}{.spec.template.spec.containers[0].image}{\" \"}{.spec.replicas}{\"\n\"}{end}" 2>/dev/null | awk "\$1==\"nginx:1.25-alpine\"{print \$2}")"
    [ "$desired" = "nginx:1.25-alpine" ] && { [ -z "$new_rs_replicas" ] || [ "$new_rs_replicas" = "0" ]; }
  '

print_score
