#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q101-06-create-deployment-imperative${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Deployment 'api-server' exists in $QUESTION_ID" \
  resource_exists deployment api-server -n "$QUESTION_ID"

check_criterion "Deployment 'api-server' runs image 'nginx:1.25-alpine'" \
  [ "$(kget deployment api-server '{.spec.template.spec.containers[0].image}' -n "$QUESTION_ID")" = "nginx:1.25-alpine" ]

check_criterion "Deployment 'api-server' has 3 replicas configured" \
  [ "$(kget deployment api-server '{.spec.replicas}' -n "$QUESTION_ID")" = "3" ]

check_criterion "Deployment 'api-server' has 3 ready replicas" \
  [ "$(kget deployment api-server '{.status.readyReplicas}' -n "$QUESTION_ID")" = "3" ]

print_score
