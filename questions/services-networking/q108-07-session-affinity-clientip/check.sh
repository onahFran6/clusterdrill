#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q108-07-session-affinity-clientip${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

# "Exists" alone would trivially pass against setup.sh's own seeded Service,
# so every criterion below requires the *affinity change* specifically -
# none of them can be satisfied by the unsolved, freshly-seeded state.

check_criterion "Service 'session-store-svc' sessionAffinity is ClientIP" \
  [ "$(kget service session-store-svc '{.spec.sessionAffinity}' -n "$QUESTION_ID")" = "ClientIP" ]

check_criterion "Service 'session-store-svc' ClientIP timeout is 3600 seconds" \
  [ "$(kget service session-store-svc '{.spec.sessionAffinityConfig.clientIP.timeoutSeconds}' -n "$QUESTION_ID")" = "3600" ]

check_criterion "Service 'session-store-svc' kept its original selector and type while gaining affinity" \
  bash -c "[ \"\$(kubectl get service session-store-svc -n '$QUESTION_ID' -o jsonpath='{.spec.selector.app}')\" = 'session-store' ] && \
    [ \"\$(kubectl get service session-store-svc -n '$QUESTION_ID' -o jsonpath='{.spec.type}')\" = 'ClusterIP' ] && \
    [ \"\$(kubectl get service session-store-svc -n '$QUESTION_ID' -o jsonpath='{.spec.sessionAffinity}')\" = 'ClientIP' ]"

print_score
