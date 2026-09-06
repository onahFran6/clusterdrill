#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q106-12-runasnonroot-enforced${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Pod 'hardened-app' exists in $QUESTION_ID" \
  resource_exists pod hardened-app -n "$QUESTION_ID"

check_criterion "Pod 'hardened-app' securityContext.runAsNonRoot is true" \
  [ "$(kget pod hardened-app '{.spec.securityContext.runAsNonRoot}' -n "$QUESTION_ID")" = "true" ]

kubectl wait --for=condition=Ready pod/hardened-app -n "$QUESTION_ID" --timeout=30s >/dev/null 2>&1

check_criterion "Pod 'hardened-app' reached Running phase" \
  [ "$(kget pod hardened-app '{.status.phase}' -n "$QUESTION_ID")" = "Running" ]

print_score
