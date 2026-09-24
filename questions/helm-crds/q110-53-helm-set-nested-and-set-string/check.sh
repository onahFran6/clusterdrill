#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q110-53-helm-set-nested-and-set-string${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

# If buildFlag landed as a bool instead of a string, the ConfigMap was
# invalid and the whole release failed to install - so this one status
# check is also an indirect proof that --set-string was used correctly.
STATUS_JSON="$(helm status web -n "$QUESTION_ID" -o json 2>/dev/null)"
IS_DEPLOYED="no"
echo "$STATUS_JSON" | grep -q '"status":"deployed"' && IS_DEPLOYED="yes"
check_criterion "Release 'web' is deployed" \
  [ "$IS_DEPLOYED" = "yes" ]

check_criterion "Ingress 'web-web' routes host app.example.com" \
  [ "$(kget ingress web-web '{.spec.rules[0].host}' -n "$QUESTION_ID")" = "app.example.com" ]

check_criterion "Deployment 'web-web' container cpu limit is 500m" \
  [ "$(kget deployment web-web '{.spec.template.spec.containers[0].resources.limits.cpu}' -n "$QUESTION_ID")" = "500m" ]

check_criterion "ConfigMap 'web-web-extra' data.buildFlag is the literal string \"true\"" \
  [ "$(kget configmap web-web-extra '{.data.buildFlag}' -n "$QUESTION_ID")" = "true" ]

print_score
