#!/usr/bin/env bash
# No "set -e" - a failed criterion is a normal result, not a script error.
set -uo pipefail

QUESTION_ID="q110-21-helm-multiple-value-files${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Deployment 'stack-stacker' exists in namespace $QUESTION_ID" \
  resource_exists deployment stack-stacker -n "$QUESTION_ID"

check_criterion "Deployment 'stack-stacker' has 3 replicas (from overrides/prod-values.yaml)" \
  [ "$(kget deployment stack-stacker '{.spec.replicas}' -n "$QUESTION_ID")" = "3" ]

check_criterion "Pod template carries label tier=prod (from overrides/prod-values.yaml)" \
  [ "$(kget deployment stack-stacker '{.spec.template.metadata.labels.tier}' -n "$QUESTION_ID")" = "prod" ]

check_criterion "Container image is still nginx:1.25-alpine (chart default merged, not replaced)" \
  [ "$(kget deployment stack-stacker '{.spec.template.spec.containers[0].image}' -n "$QUESTION_ID")" = "nginx:1.25-alpine" ]

print_score
