#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q101-18-annotate-resource${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Deployment 'billing-api' has annotation owner-team=billing-platform" \
  [ "$(kget deployment billing-api '{.metadata.annotations.owner-team}' -n "$QUESTION_ID")" = "billing-platform" ]

annotated_without_touching_image() {
  [ "$(kget deployment billing-api '{.metadata.annotations.owner-team}' -n "$QUESTION_ID")" = "billing-platform" ] &&
    [ "$(kget deployment billing-api '{.spec.template.spec.containers[0].image}' -n "$QUESTION_ID")" = "nginx:1.25-alpine" ]
}
check_criterion "Deployment 'billing-api' still runs image 'nginx:1.25-alpine' (untouched by the annotate step)" \
  annotated_without_touching_image

print_score
