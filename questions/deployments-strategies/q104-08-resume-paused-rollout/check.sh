#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q104-08-resume-paused-rollout${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Deployment 'reporting' is not paused" \
  [ "$(kget deployment reporting '{.spec.paused}' -n "$QUESTION_ID")" != "true" ]

check_criterion "Deployment 'reporting' fully rolled out on nginx:1.25-alpine with 3 ready replicas" \
  bash -c '
    image="$(kubectl get deployment reporting -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.containers[0].image}" 2>/dev/null)"
    ready="$(kubectl get deployment reporting -n "'"$QUESTION_ID"'" -o jsonpath="{.status.readyReplicas}" 2>/dev/null)"
    updated="$(kubectl get deployment reporting -n "'"$QUESTION_ID"'" -o jsonpath="{.status.updatedReplicas}" 2>/dev/null)"
    [ "$image" = "nginx:1.25-alpine" ] && [ "$ready" = "3" ] && [ "$updated" = "3" ]
  '

check_criterion "No non-terminating pod still runs the old nginx:1.24-alpine image" \
  bash -c '
    old_count="$(kubectl get pods -n "'"$QUESTION_ID"'" -l app=reporting -o jsonpath="{range .items[*]}{.metadata.deletionTimestamp}{\"|\"}{.spec.containers[0].image}{\"\n\"}{end}" 2>/dev/null | awk -F"|" "\$1==\"\" && \$2==\"nginx:1.24-alpine\"" | wc -l | tr -d " ")"
    [ "$old_count" = "0" ]
  '

print_score
