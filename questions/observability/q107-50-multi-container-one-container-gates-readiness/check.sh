#!/usr/bin/env bash
# No "set -e" - a failed criterion is a normal result, not a script error.
set -uo pipefail

QUESTION_ID="q107-50-multi-container-one-container-gates-readiness${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "'cache's readinessProbe now targets port 80, the other two containers are unchanged, and the whole Pod is Ready" \
  bash -c '
    port="$(kubectl get pod web-stack -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.containers[?(@.name==\"cache\")].readinessProbe.httpGet.port}" 2>/dev/null)"
    [ "$port" = "80" ] || exit 1
    fe_image="$(kubectl get pod web-stack -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.containers[?(@.name==\"frontend\")].image}" 2>/dev/null)"
    [ "$fe_image" = "nginx:1.25-alpine" ] || exit 1
    lg_image="$(kubectl get pod web-stack -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.containers[?(@.name==\"logger\")].image}" 2>/dev/null)"
    [ "$lg_image" = "busybox:1.36" ] || exit 1
    ready="$(kubectl get pod web-stack -n "'"$QUESTION_ID"'" -o jsonpath="{.status.conditions[?(@.type==\"Ready\")].status}" 2>/dev/null)"
    [ "$ready" = "True" ]
  '

print_score
