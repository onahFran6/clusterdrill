#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q101-04-expose-pod-clusterip${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Service 'catalog-svc' exists in $QUESTION_ID" \
  resource_exists service catalog-svc -n "$QUESTION_ID"

check_criterion "Service 'catalog-svc' is type ClusterIP" \
  [ "$(kget service catalog-svc '{.spec.type}' -n "$QUESTION_ID")" = "ClusterIP" ]

check_criterion "Service 'catalog-svc' listens on port 80" \
  [ "$(kget service catalog-svc '{.spec.ports[0].port}' -n "$QUESTION_ID")" = "80" ]

check_criterion "Service 'catalog-svc' targets container port 80" \
  [ "$(kget service catalog-svc '{.spec.ports[0].targetPort}' -n "$QUESTION_ID")" = "80" ]

check_criterion "Service 'catalog-svc' selects app=catalog" \
  [ "$(kget service catalog-svc '{.spec.selector.app}' -n "$QUESTION_ID")" = "catalog" ]

print_score
