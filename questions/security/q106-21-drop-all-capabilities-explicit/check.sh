#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q106-21-drop-all-capabilities-explicit${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

DROP_LIST="$(kget pod audit-agent '{.spec.containers[0].securityContext.capabilities.drop}' -n "$QUESTION_ID")"
ADD_LIST="$(kget pod audit-agent '{.spec.containers[0].securityContext.capabilities.add}' -n "$QUESTION_ID")"

check_criterion "Container 'audit-agent' drops capability 'ALL' and adds none back" \
  bash -c "[ '$DROP_LIST' = '[\"ALL\"]' ] && [ -z '$ADD_LIST' ]"

kubectl wait --for=condition=Ready pod/audit-agent -n "$QUESTION_ID" --timeout=60s >/dev/null 2>&1
AGENT_PHASE="$(kget pod audit-agent '{.status.phase}' -n "$QUESTION_ID")"
AGENT_IMAGE="$(kget pod audit-agent '{.spec.containers[0].image}' -n "$QUESTION_ID")"
AGENT_DROP="$(kget pod audit-agent '{.spec.containers[0].securityContext.capabilities.drop}' -n "$QUESTION_ID")"

check_criterion "Pod 'audit-agent' reaches Running with image unchanged and the hardened setting applied" \
  bash -c "[ '$AGENT_PHASE' = 'Running' ] && [ '$AGENT_IMAGE' = 'busybox:1.36' ] && [ '$AGENT_DROP' = '[\"ALL\"]' ]"

print_score
