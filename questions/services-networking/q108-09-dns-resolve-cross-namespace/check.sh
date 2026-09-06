#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q108-09-dns-resolve-cross-namespace${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

expected_ip="$(kget service kubernetes '{.spec.clusterIP}' -n default)"

check_criterion "ConfigMap 'cross-ns-lookup-result' exists in $QUESTION_ID" \
  resource_exists configmap cross-ns-lookup-result -n "$QUESTION_ID"

check_criterion "ConfigMap has non-empty 'service-ip' key" \
  [ -n "$(kget configmap cross-ns-lookup-result '{.data.service-ip}' -n "$QUESTION_ID")" ]

check_criterion "'service-ip' matches default/kubernetes Service's live ClusterIP ($expected_ip)" \
  [ "$(kget configmap cross-ns-lookup-result '{.data.service-ip}' -n "$QUESTION_ID")" = "$expected_ip" ]

print_score
