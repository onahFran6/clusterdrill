#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q104-10-revision-history-limit${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Deployment 'audit-log' has revisionHistoryLimit=2" \
  [ "$(kget deployment audit-log '{.spec.revisionHistoryLimit}' -n "$QUESTION_ID")" = "2" ]

check_criterion "Deployment 'audit-log' rolled out to nginx:1.26-alpine successfully" \
  bash -c '
    image="$(kubectl get deployment audit-log -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.containers[0].image}" 2>/dev/null)"
    ready="$(kubectl get deployment audit-log -n "'"$QUESTION_ID"'" -o jsonpath="{.status.readyReplicas}" 2>/dev/null)"
    [ "$image" = "nginx:1.26-alpine" ] && [ "$ready" = "2" ]
  '

check_criterion "At most 2 old (scaled-to-0) ReplicaSets remain for 'audit-log'" \
  bash -c '
    old_count="$(kubectl get rs -n "'"$QUESTION_ID"'" -l app=audit-log -o jsonpath="{range .items[?(@.spec.replicas==0)]}{.metadata.name}{\"\n\"}{end}" 2>/dev/null | sed "/^\$/d" | wc -l | tr -d " ")"
    [ "$old_count" -le 2 ]
  '

print_score
