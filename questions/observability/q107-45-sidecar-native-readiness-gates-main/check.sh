#!/usr/bin/env bash
# No "set -e" - a failed criterion is a normal result, not a script error.
set -uo pipefail

QUESTION_ID="q107-45-sidecar-native-readiness-gates-main${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Native sidecar 'metrics-sidecar' readinessProbe now targets port 80, restartPolicy Always unchanged, main container image unchanged, and the whole Pod is Ready" \
  bash -c '
    port="$(kubectl get pod metrics-app -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.initContainers[0].readinessProbe.httpGet.port}" 2>/dev/null)"
    [ "$port" = "80" ] || exit 1
    rp="$(kubectl get pod metrics-app -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.initContainers[0].restartPolicy}" 2>/dev/null)"
    [ "$rp" = "Always" ] || exit 1
    main_image="$(kubectl get pod metrics-app -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.containers[0].image}" 2>/dev/null)"
    [ "$main_image" = "nginx:1.25-alpine" ] || exit 1
    ready="$(kubectl get pod metrics-app -n "'"$QUESTION_ID"'" -o jsonpath="{.status.conditions[?(@.type==\"Ready\")].status}" 2>/dev/null)"
    [ "$ready" = "True" ]
  '

print_score
