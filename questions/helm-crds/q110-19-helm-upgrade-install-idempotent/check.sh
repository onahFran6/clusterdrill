#!/usr/bin/env bash
# No "set -e" - a failed criterion is a normal result, not a script error.
set -uo pipefail

QUESTION_ID="q110-19-helm-upgrade-install-idempotent${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

RELEASE_STATUS="$(helm status flags -n "$QUESTION_ID" -o json 2>/dev/null)"
RELEASE_STATE="$(echo "$RELEASE_STATUS" | grep -o '"status":"[a-z]*"' | head -1 | cut -d: -f2 | tr -d '"')"
REVISION_NUM="$(echo "$RELEASE_STATUS" | grep -o '"version":[0-9]*' | head -1 | cut -d: -f2)"
REVISION_NUM="${REVISION_NUM:-0}"

check_criterion "Release 'flags' exists with status 'deployed'" \
  [ "$RELEASE_STATE" = "deployed" ]

check_criterion "Release 'flags' is at revision 1 (created via a single upgrade --install, not installed then upgraded)" \
  [ "$REVISION_NUM" -eq 1 ]

check_criterion "Deployment 'flags-toggle' exists" \
  resource_exists deployment flags-toggle -n "$QUESTION_ID"

check_criterion "Deployment 'flags-toggle' container has env FEATURE_FLAG=on" \
  [ "$(kget deployment flags-toggle '{.spec.template.spec.containers[0].env[?(@.name=="FEATURE_FLAG")].value}' -n "$QUESTION_ID")" = "on" ]

check_criterion "ConfigMap 'flags-toggle-cm' exists" \
  resource_exists configmap flags-toggle-cm -n "$QUESTION_ID"

check_criterion "ConfigMap 'flags-toggle-cm' has data.flag=on" \
  [ "$(kget configmap flags-toggle-cm '{.data.flag}' -n "$QUESTION_ID")" = "on" ]

print_score
