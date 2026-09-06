#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q108-01-nodeport-fixed-port${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Service 'metrics-agent-svc' exists in $QUESTION_ID" \
  resource_exists service metrics-agent-svc -n "$QUESTION_ID"

check_criterion "Service 'metrics-agent-svc' is type NodePort" \
  [ "$(kget service metrics-agent-svc '{.spec.type}' -n "$QUESTION_ID")" = "NodePort" ]

check_criterion "Service 'metrics-agent-svc' selects app=metrics-agent" \
  [ "$(kget service metrics-agent-svc '{.spec.selector.app}' -n "$QUESTION_ID")" = "metrics-agent" ]

check_criterion "Service 'metrics-agent-svc' listens on port 80 forwarding to 80" \
  bash -c "[ \"\$(kubectl get service metrics-agent-svc -n '$QUESTION_ID' -o jsonpath='{.spec.ports[0].port}')\" = '80' ] && \
    [ \"\$(kubectl get service metrics-agent-svc -n '$QUESTION_ID' -o jsonpath='{.spec.ports[0].targetPort}')\" = '80' ]"

check_criterion "Service 'metrics-agent-svc' pins nodePort to 30080" \
  [ "$(kget service metrics-agent-svc '{.spec.ports[0].nodePort}' -n "$QUESTION_ID")" = "30080" ]

print_score
