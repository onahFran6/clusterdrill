#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q101-02-create-pod-labels-port${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Pod 'label-demo' exists in $QUESTION_ID" \
  resource_exists pod label-demo -n "$QUESTION_ID"

check_criterion "Pod 'label-demo' runs image 'httpd:2.4-alpine'" \
  [ "$(kget pod label-demo '{.spec.containers[0].image}' -n "$QUESTION_ID")" = "httpd:2.4-alpine" ]

check_criterion "Pod 'label-demo' has label app=label-demo" \
  [ "$(kget pod label-demo '{.metadata.labels.app}' -n "$QUESTION_ID")" = "label-demo" ]

check_criterion "Pod 'label-demo' has label tier=frontend" \
  [ "$(kget pod label-demo '{.metadata.labels.tier}' -n "$QUESTION_ID")" = "frontend" ]

check_criterion "Pod 'label-demo' container exposes port 8080" \
  [ "$(kget pod label-demo '{.spec.containers[0].ports[0].containerPort}' -n "$QUESTION_ID")" = "8080" ]

print_score
