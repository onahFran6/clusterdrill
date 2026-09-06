#!/usr/bin/env bash
# No "set -e" - a failed criterion is a normal result, not a script error.
set -uo pipefail

QUESTION_ID="q104-37-set-env-var-triggers-rollout${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Container 'worker' has env var LOG_LEVEL=debug" \
  [ "$(kget deployment worker '{.spec.template.spec.containers[?(@.name=="worker")].env[?(@.name=="LOG_LEVEL")].value}' -n "$QUESTION_ID")" = "debug" ]

check_criterion "Deployment 'worker' rollout completed: 2 ready and 2 updated on the new template" \
  bash -c '
    env_val="$(kubectl get deployment worker -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.containers[?(@.name==\"worker\")].env[?(@.name==\"LOG_LEVEL\")].value}" 2>/dev/null)"
    ready="$(kubectl get deployment worker -n "'"$QUESTION_ID"'" -o jsonpath="{.status.readyReplicas}" 2>/dev/null)"
    updated="$(kubectl get deployment worker -n "'"$QUESTION_ID"'" -o jsonpath="{.status.updatedReplicas}" 2>/dev/null)"
    [ "$env_val" = "debug" ] && [ "$ready" = "2" ] && [ "$updated" = "2" ]
  '

print_score
