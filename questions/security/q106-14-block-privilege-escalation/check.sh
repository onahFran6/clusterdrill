#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q106-14-block-privilege-escalation${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Container 'legacy-worker' has allowPrivilegeEscalation=false" \
  [ "$(kget pod legacy-worker '{.spec.containers[0].securityContext.allowPrivilegeEscalation}' -n "$QUESTION_ID")" = "false" ]

kubectl wait --for=condition=Ready pod/legacy-worker -n "$QUESTION_ID" --timeout=60s >/dev/null 2>&1
LEGACY_PHASE="$(kget pod legacy-worker '{.status.phase}' -n "$QUESTION_ID")"
LEGACY_ESCALATION="$(kget pod legacy-worker '{.spec.containers[0].securityContext.allowPrivilegeEscalation}' -n "$QUESTION_ID")"

check_criterion "Pod 'legacy-worker' reaches Running with the hardened setting applied" \
  bash -c "[ '$LEGACY_PHASE' = 'Running' ] && [ '$LEGACY_ESCALATION' = 'false' ]"

print_score
