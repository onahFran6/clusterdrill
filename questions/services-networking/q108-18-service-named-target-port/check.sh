#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q108-18-service-named-target-port${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Service 'image-resizer-svc' exists in $QUESTION_ID" \
  resource_exists service image-resizer-svc -n "$QUESTION_ID"

check_criterion "Service 'image-resizer-svc' is type ClusterIP" \
  [ "$(kget service image-resizer-svc '{.spec.type}' -n "$QUESTION_ID")" = "ClusterIP" ]

check_criterion "Service 'image-resizer-svc' selects app=image-resizer" \
  [ "$(kget service image-resizer-svc '{.spec.selector.app}' -n "$QUESTION_ID")" = "image-resizer" ]

check_criterion "Service 'image-resizer-svc' listens on port 80" \
  [ "$(kget service image-resizer-svc '{.spec.ports[0].port}' -n "$QUESTION_ID")" = "80" ]

check_criterion "Service 'image-resizer-svc' targetPort is the name 'worker-port', not a number" \
  [ "$(kget service image-resizer-svc '{.spec.ports[0].targetPort}' -n "$QUESTION_ID")" = "worker-port" ]

print_score
