#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q104-02-rollout-history-change-cause${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Deployment 'pricing' image updated to nginx:1.25-alpine" \
  [ "$(kget deployment pricing '{.spec.template.spec.containers[0].image}' -n "$QUESTION_ID")" = "nginx:1.25-alpine" ]

check_criterion "Deployment 'pricing' rollout is fully available on the new image" \
  bash -c '
    image="$(kubectl get deployment pricing -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.containers[0].image}" 2>/dev/null)"
    ready="$(kubectl get deployment pricing -n "'"$QUESTION_ID"'" -o jsonpath="{.status.readyReplicas}" 2>/dev/null)"
    updated="$(kubectl get deployment pricing -n "'"$QUESTION_ID"'" -o jsonpath="{.status.updatedReplicas}" 2>/dev/null)"
    [ "$image" = "nginx:1.25-alpine" ] && [ "$ready" = "3" ] && [ "$updated" = "3" ]
  '

check_criterion "Latest ReplicaSet for 'pricing' carries the change-cause annotation" \
  bash -c '
    rs="$(kubectl get rs -n "'"$QUESTION_ID"'" -l app=pricing -o jsonpath="{.items[?(@.metadata.annotations.deployment\.kubernetes\.io/revision)].metadata.annotations.kubernetes\.io/change-cause}" 2>/dev/null)"
    echo "$rs" | grep -qi "1.25-alpine"
  '

check_criterion "Deployment rollout history contains more than one revision" \
  bash -c '[ "$(kubectl rollout history deployment/pricing -n "'"$QUESTION_ID"'" 2>/dev/null | grep -cE "^[0-9]+ ")" -ge 2 ]'

print_score
