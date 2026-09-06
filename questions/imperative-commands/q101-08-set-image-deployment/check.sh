#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q101-08-set-image-deployment${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Container 'app' now runs image 'nginx:1.25-alpine'" \
  [ "$(kget deployment image-rollout '{.spec.template.spec.containers[0].image}' -n "$QUESTION_ID")" = "nginx:1.25-alpine" ]

check_criterion "Rollout completed - running pod's container also uses nginx:1.25-alpine" \
  bash -c "kubectl get pods -n '$QUESTION_ID' -l app=image-rollout -o jsonpath='{.items[0].spec.containers[0].image}' 2>/dev/null | grep -q '^nginx:1.25-alpine$'"

print_score
