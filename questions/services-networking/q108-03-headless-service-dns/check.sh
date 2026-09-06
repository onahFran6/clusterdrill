#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q108-03-headless-service-dns${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Service 'cache-node-headless' exists in $QUESTION_ID" \
  resource_exists service cache-node-headless -n "$QUESTION_ID"

check_criterion "Service 'cache-node-headless' has clusterIP set to None (headless)" \
  [ "$(kget service cache-node-headless '{.spec.clusterIP}' -n "$QUESTION_ID")" = "None" ]

check_criterion "Service 'cache-node-headless' selects app=cache-node" \
  [ "$(kget service cache-node-headless '{.spec.selector.app}' -n "$QUESTION_ID")" = "cache-node" ]

check_criterion "Service 'cache-node-headless' listens on port 6379 forwarding to 6379" \
  bash -c "[ \"\$(kubectl get service cache-node-headless -n '$QUESTION_ID' -o jsonpath='{.spec.ports[0].port}')\" = '6379' ] && \
    [ \"\$(kubectl get service cache-node-headless -n '$QUESTION_ID' -o jsonpath='{.spec.ports[0].targetPort}')\" = '6379' ]"

check_criterion "Headless Service has ready endpoints (pods backing it)" \
  bash -c "eps=\$(kubectl get endpoints cache-node-headless -n '$QUESTION_ID' -o jsonpath='{.subsets[*].addresses[*].ip}' 2>/dev/null); [ -n \"\$eps\" ]"

print_score
