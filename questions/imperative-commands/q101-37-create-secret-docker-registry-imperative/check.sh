#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q101-37-create-secret-docker-registry-imperative${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Secret 'registry-cred' exists in $QUESTION_ID" \
  resource_exists secret registry-cred -n "$QUESTION_ID"

check_criterion "Secret 'registry-cred' is type kubernetes.io/dockerconfigjson" \
  bash -c "[ \"\$(kubectl get secret registry-cred -n '$QUESTION_ID' -o jsonpath='{.type}' 2>/dev/null)\" = 'kubernetes.io/dockerconfigjson' ]"

check_criterion "Secret 'registry-cred' has the exact registry credentials requested" \
  bash -c "
    payload=\$(kubectl get secret registry-cred -n '$QUESTION_ID' -o jsonpath='{.data.\.dockerconfigjson}' 2>/dev/null | base64 -d 2>/dev/null)
    [ -n \"\$payload\" ] &&
    echo \"\$payload\" | jq -e '
      .auths[\"registry.example.com\"] as \$entry |
      \$entry.username == \"svc-deploy\" and
      \$entry.password == \"sup3r-secret!\" and
      \$entry.email == \"svc-deploy@example.com\" and
      ((\$entry.auth | @base64d) == \"svc-deploy:sup3r-secret!\")
    ' >/dev/null 2>&1
  "

print_score
