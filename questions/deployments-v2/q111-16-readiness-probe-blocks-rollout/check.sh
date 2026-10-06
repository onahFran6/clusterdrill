#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q111-16-readiness-probe-blocks-rollout${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Readiness probe now checks path / (every 5s, as seeded)" \
  bash -c '
    path="$(kubectl get deployment menu -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.containers[0].readinessProbe.httpGet.path}" 2>/dev/null)"
    period="$(kubectl get deployment menu -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.containers[0].readinessProbe.periodSeconds}" 2>/dev/null)"
    [ "$path" = "/" ] && [ "$period" = "5" ]
  '

check_criterion "Rollout completed: 3/3 ready and updated" \
  bash -c '
    ready="$(kubectl get deployment menu -n "'"$QUESTION_ID"'" -o jsonpath="{.status.readyReplicas}" 2>/dev/null)"
    updated="$(kubectl get deployment menu -n "'"$QUESTION_ID"'" -o jsonpath="{.status.updatedReplicas}" 2>/dev/null)"
    [ "$ready" = "3" ] && [ "$updated" = "3" ]
  '

print_score
