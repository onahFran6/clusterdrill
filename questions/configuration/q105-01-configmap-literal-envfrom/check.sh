#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e` -
# a failed criterion is a normal result, not a script error.
set -uo pipefail

QUESTION_ID="q105-01-configmap-literal-envfrom${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "ConfigMap 'catalog-env' exists" \
  resource_exists configmap catalog-env -n "$QUESTION_ID"

check_criterion "ConfigMap 'catalog-env' has CATALOG_MODE=readonly" \
  [ "$(kget configmap catalog-env '{.data.CATALOG_MODE}' -n "$QUESTION_ID")" = "readonly" ]

check_criterion "ConfigMap 'catalog-env' has CATALOG_REGION=eu-west-1" \
  [ "$(kget configmap catalog-env '{.data.CATALOG_REGION}' -n "$QUESTION_ID")" = "eu-west-1" ]

check_criterion "Pod 'catalog-app' container uses envFrom with configMapRef catalog-env" \
  [ "$(kget pod catalog-app '{.spec.containers[0].envFrom[0].configMapRef.name}' -n "$QUESTION_ID")" = "catalog-env" ]

check_criterion "Container actually sees CATALOG_MODE=readonly" \
  [ "$(kubectl exec -n "$QUESTION_ID" catalog-app -- sh -c 'echo $CATALOG_MODE' 2>/dev/null)" = "readonly" ]

check_criterion "Container actually sees CATALOG_REGION=eu-west-1" \
  [ "$(kubectl exec -n "$QUESTION_ID" catalog-app -- sh -c 'echo $CATALOG_REGION' 2>/dev/null)" = "eu-west-1" ]

print_score
