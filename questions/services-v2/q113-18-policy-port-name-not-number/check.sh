#!/usr/bin/env bash
# Mixed grading: the container port's name is a real, live field (checked
# directly). The NetworkPolicy's own port-by-name fix is spec-only, same
# rationale as every other NetworkPolicy question in this bank - this
# cluster's default CNI does not enforce NetworkPolicy.
set -uo pipefail

QUESTION_ID="q113-18-policy-port-name-not-number${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Deployment 'web' container port is named 'http' on containerPort 80" \
  bash -c "[ \"\$(kubectl get deployment web -n '$QUESTION_ID' -o jsonpath='{.spec.template.spec.containers[0].ports[0].name}')\" = 'http' ] && \
    [ \"\$(kubectl get deployment web -n '$QUESTION_ID' -o jsonpath='{.spec.template.spec.containers[0].ports[0].containerPort}')\" = '80' ]"

check_criterion "NetworkPolicy 'allow-client' references the port by name 'http', not by number" \
  [ "$(kget networkpolicy allow-client '{.spec.ingress[0].ports[0].port}' -n "$QUESTION_ID")" = "http" ]

print_score
