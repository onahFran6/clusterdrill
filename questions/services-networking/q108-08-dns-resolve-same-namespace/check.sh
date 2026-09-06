#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q108-08-dns-resolve-same-namespace${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

expected_ip="$(kget service inventory-svc '{.spec.clusterIP}' -n "$QUESTION_ID")"

check_criterion "ConfigMap 'dns-lookup-result' exists in $QUESTION_ID" \
  resource_exists configmap dns-lookup-result -n "$QUESTION_ID"

check_criterion "ConfigMap has non-empty 'service-ip' key" \
  [ -n "$(kget configmap dns-lookup-result '{.data.service-ip}' -n "$QUESTION_ID")" ]

check_criterion "'service-ip' matches inventory-svc's live ClusterIP ($expected_ip)" \
  [ "$(kget configmap dns-lookup-result '{.data.service-ip}' -n "$QUESTION_ID")" = "$expected_ip" ]

print_score
